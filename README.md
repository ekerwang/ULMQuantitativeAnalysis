# ULMQuantitativeAnalysis

This repository contains the **open-source code and example data** accompanying the manuscript:

> Wang Yike, Lowerison Matthew R, Huang Zhe, You Qi, Lin Bing-Ze, Llano Daniel A, Song Pengfei (2024)  
> *Longitudinal Awake Imaging of Mouse Deep Brain Microvasculature with Super-resolution Ultrasound Localization Microscopy*  
> eLife 13:RP95168  
> https://doi.org/10.7554/eLife.95168.2

---

## Overview

This repository provides MATLAB-based tools designed to support **ROI-based quantitative analysis** of ULM (Ultrasound Localization Microscopy) images. The main component is a MATLAB App (`mlapp`), intended to facilitate intuitive interaction and analysis of large-scale ULM mouse brain imaging datasets.

⚠️ **Note:** This is a *pre-release version*. We will continue to update the repository prior to the final publication and will include comprehensive instructions and tutorials.

---

## System Requirements

- MATLAB **2025a or later** is required to run the `.mlapp` application.
- Compatibility issues may occur with earlier versions of MATLAB.
- A standalone **installation package** using MATLAB Runtime will be released soon, allowing users to run the application without a full MATLAB installation.

---

## Acknowledgments

We gratefully acknowledge the following work for providing a MATLAB-based brain atlas registration framework:

> Brunner, C., Grillet, M., Urban, A. et al. (2021)  
> *Whole-brain functional ultrasound imaging in awake head-fixed mice.*  
> *Nature Protocols*, 16, 3547–3571  
> https://doi.org/10.1038/s41596-021-00548-8  
> GitHub: [nerf-common/whole-brain-fUS](https://github.com/nerf-common/whole-brain-fUS)

Their codebase inspired several components of our ROI and registration pipeline.

---

## Citation

If you use this codebase in your research, please cite the following article:

> Wang Yike, Lowerison Matthew R, Huang Zhe, You Qi, Lin Bing-Ze, Llano Daniel A, Song Pengfei (2024)  
> *Longitudinal Awake Imaging of Mouse Deep Brain Microvasculature with Super-resolution Ultrasound Localization Microscopy*  
> *eLife* 13:RP95168  
> https://doi.org/10.7554/eLife.95168.2
