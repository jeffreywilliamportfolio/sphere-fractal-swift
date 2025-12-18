#include <metal_stdlib>
using namespace metal;

struct Uniforms {
    float2 uResolution;
    float3 uCameraPos;
    float3 uCameraDir;
    float3 uCameraUp;
    float3 uOffset;
    float uLogScale;
    float uTime;
    
    // Lighting
    float3 uLightDir;
    float uShadowSoftness;
    float3 uTrapColor;
    float3 uBaseColor;
    float uAmbientIntensity;
};

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

vertex VertexOut fullscreenVertex(uint vid [[vertex_id]]) {
    // Fullscreen triangle
    float2 pos;
    switch (vid) {
        case 0: pos = float2(-1.0, -1.0); break;
        case 1: pos = float2( 3.0, -1.0); break;
        default: pos = float2(-1.0,  3.0); break;
    }

    VertexOut out;
    out.position = float4(pos, 0.0, 1.0);
    out.uv = pos * 0.5 + 0.5;
    return out;
}

// MARK: - SDF / Scene

static constant int MAX_STEPS = 128;
static constant float MIN_DIST = 0.001;
static constant float MAX_DIST = 100.0;
static constant float SPHERE_RADIUS = 4.5;

static constant int BULB_ITERS = 8;
static constant float BULB_POWER = 8.0;

float sceneSDF(float3 p, constant Uniforms& u);

// MARK: - Palette / Shimmer helpers

float hash31(float3 p) {
    return fract(sin(dot(p, float3(127.1, 311.7, 74.7))) * 43758.5453123);
}

float3 paletteCosine(float t) {
    // Smooth, vibrant palette (cosine palette).
    float3 a = float3(0.55, 0.50, 0.52);
    float3 b = float3(0.45, 0.45, 0.48);
    float3 c = float3(1.00, 1.00, 1.00);
    float3 d = float3(0.00, 0.33, 0.67);
    return a + b * cos(6.2831853 * (c * t + d));
}

float3 srgbToLinear(float3 c) {
    // Exact sRGB EOTF (piecewise).
    float3 x = clamp(c, 0.0, 1.0);
    float3 lo = x / 12.92;
    float3 hi = pow((x + 0.055) / 1.055, float3(2.4));
    return select(hi, lo, x <= 0.04045);
}

float3 toneMapACES(float3 x) {
    // Narkowicz 2015, "ACES Filmic Tone Mapping Curve".
    const float a = 2.51;
    const float b = 0.03;
    const float c = 2.43;
    const float d = 0.59;
    const float e = 0.14;
    return clamp((x * (a * x + b)) / (x * (c * x + d) + e), 0.0, 1.0);
}

float sphereConstraint(float3 p) {
    return length(p) - SPHERE_RADIUS;
}

float softShadow(float3 ro, float3 rd, float k, constant Uniforms& u) {
    float res = 1.0;
    float t = 0.01;
    for (int i = 0; i < 32; i++) {
        float h = sceneSDF(ro + rd * t, u);
        if (h < 0.001) return 0.0;
        res = min(res, k * h / t);
        t += h;
        if (t > 10.0) break;
    }
    return clamp(res, 0.0, 1.0);
}

// Returns (distance, trap)
float2 mapMandelbulb(float3 p, constant Uniforms& u) {
    float scale = exp(u.uLogScale);
    float3 c = (p - u.uOffset) * scale;
    float3 z = c;

    float dr = 1.0;
    float r = 0.0;
    float trap = 1e20; // Start with huge distance

    for (int i = 0; i < BULB_ITERS; i++) {
        r = length(z);
        if (r > 2.0) { break; }
        
        // Orbit trap: track min distance to origin
        trap = min(trap, r);

        float rSafe = max(r, 1e-6);
        float theta = acos(clamp(z.z / rSafe, -1.0f, 1.0f));
        float phi = atan2(z.y, z.x);

        dr = pow(rSafe, BULB_POWER - 1.0) * BULB_POWER * dr + 1.0;

        float zr = pow(rSafe, BULB_POWER);
        theta *= BULB_POWER;
        phi *= BULB_POWER;

        z = zr * float3(
            sin(theta) * cos(phi),
            sin(theta) * sin(phi),
            cos(theta)
        );
        z += c;
    }

    float rSafe = max(r, 1e-6);
    float dist = (0.5 * log(rSafe) * rSafe / dr);
    return float2(dist / scale, trap);
}

// Wrapper for raymarching that only needs distance
float sceneSDF(float3 p, constant Uniforms& u) {
    float2 bulb = mapMandelbulb(p, u);
    float sphere = sphereConstraint(p);
    return max(bulb.x, sphere);
}

// MARK: - Raymarch / Shading

float raymarch(float3 ro, float3 rd, constant Uniforms& u) {
    float t = 0.0;

    for (int i = 0; i < MAX_STEPS; i++) {
        float3 p = ro + rd * t;

        if (length(p) > (SPHERE_RADIUS + 1.0)) { break; }

        float d = sceneSDF(p, u);
        if (d < MIN_DIST) { return t; }
        if (t > MAX_DIST) { break; }

        t += d * 0.9;
    }
    return -1.0;
}

float3 estimateNormal(float3 p, constant Uniforms& u) {
    float h = 0.001 * (1.0 + exp(u.uLogScale)); // Scale epsilon with zoom
    float3 e1 = float3( 1.0, -1.0, -1.0);
    float3 e2 = float3(-1.0, -1.0,  1.0);
    float3 e3 = float3(-1.0,  1.0, -1.0);
    float3 e4 = float3( 1.0,  1.0,  1.0);

    float3 n =
        e1 * sceneSDF(p + e1 * h, u) +
        e2 * sceneSDF(p + e2 * h, u) +
        e3 * sceneSDF(p + e3 * h, u) +
        e4 * sceneSDF(p + e4 * h, u);

    return normalize(n);
}

float computeAO(float3 p, float3 n, constant Uniforms& u) {
    float ao = 1.0;
    float aoStep = 0.1 * (1.0 + exp(u.uLogScale) * 0.5);
    for (int i = 1; i <= 5; i++) {
        float dist = float(i) * aoStep;
        ao -= (dist - sceneSDF(p + n * dist, u)) * 0.1;
    }
    return clamp(ao, 0.0, 1.0);
}

fragment float4 fractalFragment(VertexOut in [[stage_in]], constant Uniforms& u [[buffer(0)]]) {
    float2 vUv = in.uv;
    float2 res = max(u.uResolution, float2(1.0, 1.0));

    // Background gradient (miss color)
    float3 bg0 = srgbToLinear(float3(0.05, 0.05, 0.10));
    float3 bg1 = srgbToLinear(float3(0.10, 0.10, 0.15));
    float3 background = mix(bg0, bg1, clamp(vUv.y, 0.0, 1.0));

    // Camera rays
    float2 uv = (vUv - 0.5) * 2.0;
    uv.x *= (res.x / res.y);

    float3 forward = normalize(u.uCameraDir);
    float3 up = normalize(u.uCameraUp);
    if (abs(dot(forward, up)) > 0.99) {
        up = float3(0.0, 0.0, 1.0);
    }
    float3 right = normalize(cross(forward, up));
    up = normalize(cross(right, forward));

    float3 ro = u.uCameraPos;
    float3 rd = normalize(forward + right * uv.x + up * uv.y);

    float t = raymarch(ro, rd, u);
    if (t < 0.0) {
        // Output linear; the render target is sRGB so conversion happens automatically.
        return float4(background, 1.0);
    }

    float3 p = ro + rd * t;
    float3 n = estimateNormal(p, u);
    
    // Retrieve trap data at hit point
    float2 mapData = mapMandelbulb(p, u);
    float trap = mapData.y; // Min distance to origin during iteration

    // Lighting
    float3 lightDir = normalize(u.uLightDir);
    float3 ambient = float3(u.uAmbientIntensity);
    
    // Soft Shadows
    float shadow = softShadow(p + n * 0.05, lightDir, u.uShadowSoftness, u);
    
    float ndl = max(dot(n, lightDir), 0.0);
    float3 diffuse = float3(0.8, 0.8, 0.8) * ndl * shadow; // Apply shadow to diffuse

    float3 r = reflect(-lightDir, n);
    float3 v = -rd;
    float spec = 0.8 * pow(max(dot(v, r), 0.0), 64.0) * shadow; // Sharp, strong highlights

    // --- Multi-color palette (driven by trap + position) ---
    float scale = exp(u.uLogScale);
    float zoom01 = clamp(log2(1.0 + scale) / 8.0, 0.0, 1.0);
    float trapIntensity = smoothstep(0.0, 1.0, trap);

    float shimmerPhase = u.uTime * (0.7 + 1.0 * zoom01) + dot(p, float3(1.7, 2.1, 2.7)) * 0.85;
    float hueDrift = 0.06 * sin(shimmerPhase) + 0.03 * sin(shimmerPhase * 2.13);

    float paletteT = 0.55 * (1.0 - trapIntensity);
    paletteT += 0.10 * dot(normalize(p), float3(0.7, 1.0, 1.3));
    paletteT += hueDrift;
    paletteT = fract(paletteT);

    float3 paletteColor = paletteCosine(paletteT);

    // Shimmering micro-sparkle (stable in 3D space)
    float sparkleGrid = mix(10.0, 20.0, zoom01);
    float3 cell = floor(p * sparkleGrid + 0.5);
    float cellHash = hash31(cell);
    float twinkle = 0.5 + 0.5 * sin(u.uTime * (3.0 + 2.0 * cellHash) + cellHash * 6.2831853);
    float sparkle = smoothstep(0.987, 1.0, cellHash) * twinkle;

    // Let sparkles punch specular a bit for a shimmering look.
    spec *= (1.0 + sparkle * 1.75);
    float3 specular = float3(spec);

    float ao = computeAO(p, n, u);
    float3 lighting = (ambient + diffuse + specular) * ao;

    // Trap Coloring (Inner Glow)
    // `uTrapColor`/`uBaseColor` are provided in linear space from Swift.
    float3 trapGlow = mix(u.uTrapColor, float3(1.0), 1.0 - trapIntensity); // White hot center
    
    // Base color mixed with palette + trap
    float3 baseColor = mix(u.uBaseColor, paletteColor, 0.75);
    baseColor = mix(baseColor, trapGlow, 0.4);
    baseColor *= (1.0 + 0.03 * sin(shimmerPhase * 1.31)); // subtle overall shimmer

    float3 color = lighting * baseColor;

    // Add a tiny emissive sparkle component (kept subtle so it doesn't blow out)
    float sparkleVis = sparkle * shadow * ao * (0.2 + 0.8 * ndl);
    color += (paletteColor * 1.6 + float3(0.8)) * sparkleVis * 0.35;

    // Fresnel Rim Light (Glowing Edges)
    float fresnel = pow(1.0 - max(dot(n, -rd), 0.0), 4.0);
    float3 rimColor = mix(float3(0.6, 0.8, 1.0), paletteColor, 0.6);
    color += rimColor * fresnel * 0.8;

    // Fog
    float fogAmount = 1.0 - exp(-t * 0.02);
    float3 fogColor = srgbToLinear(float3(0.1, 0.1, 0.15));
    color = mix(color, fogColor, fogAmount);

    // Vignette
    float vignette = 1.0 - length(vUv - 0.5) * 0.5;
    vignette = clamp(vignette, 0.0, 1.0);
    color *= vignette;
    
    // Post: exposure + filmic tonemap (ACES). Output stays linear.
    float exposure = 1.35;
    color *= exposure;
    color = toneMapACES(color);

    return float4(color, 1.0);
}
