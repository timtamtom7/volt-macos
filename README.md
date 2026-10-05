# Volt

A battery health monitor for macOS.

## What it does

- Charge history
- health records
- power recommendations
- heatmaps

## Targets

- macOS with widgets

## Structure

Key types:

- ``BatteryService``
- ``BatteryHealthRecord``
- ``PowerOptimizationEngine``
- ``ChargingExportService``
- ``ChargingHeatmapView``
- ``RecommendationsView``

`ChargingHeatmapView` over historical charge cycles is the useful bit — it shows degradation patterns.

## Status

Apple-platform experiment built to explore what an AI coding agent could produce for a native app. Not actively maintained.

Xcode projects here were generated with XcodeGen (`project.yml`) unless noted; open the `.xcodeproj` directly.
