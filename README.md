# Sphere Fractal Swift

An interactive Swift + Metal project for exploring 3D Mandelbulbs and fractal forms in real time.

This project is a learning-focused implementation of Apple Metal applied to rendering infinitely navigable 3D fractals. It is built to explore how GPU programming, ray marching, and real-time rendering can be used to generate immersive fractal geometry with smooth interaction and visual depth.

## Overview

Sphere Fractal Swift is a prototype and learning module centered on one core idea: using Apple’s graphics stack to render complex three-dimensional fractals efficiently and interactively.

The project uses Swift for application structure and Metal for GPU-accelerated rendering. Its purpose is both practical and educational. It demonstrates how Metal can be applied to procedural graphics while also serving as a hands-on study of fractal rendering, shader logic, and interactive 3D navigation.

## What it does

This project focuses on real-time rendering of Mandelbulb-style fractals in a navigable 3D environment. It is designed to support interactive exploration, continuous visual feedback, and an intuitive understanding of how fractal math can be translated into GPU-driven graphics.

The core emphasis is on building a rendering pipeline that feels immediate and responsive while remaining readable enough to learn from.

## Built with

Swift is used for the application layer, scene control, and platform integration.

Metal is used for low-level GPU rendering and shader-based fractal computation.

## Why this project exists

This repository was built as a way to understand Apple Metal through a concrete visual problem instead of abstract examples. Rather than treating graphics programming as isolated demos, this project applies it to something mathematically rich, visually complex, and computationally demanding.

The result is a focused exploration of how modern Apple graphics tooling can be used to create interactive 3D fractals that feel both technical and expressive.

## Current focus

The current focus of the project is real-time Mandelbulb rendering, interactive navigation, and iterative improvement of the rendering pipeline.

Depending on the version of the project, that may include camera movement, zooming, rotation, shader refinement, performance tuning, and visual experimentation with fractal parameters.

## Running the project

Clone the repository and open it in Xcode on a Mac with Metal support enabled.

```bash
git clone https://github.com/jeffreywilliamportfolio/sphere-fractal-swift.git
cd sphere-fractal-swift
