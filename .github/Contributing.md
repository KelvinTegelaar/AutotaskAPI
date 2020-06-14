## Table of Contents
1. [About the Project](#about-the-project)
1. [Project Status](#project-status)
1. [Getting Started](#getting-started)

# About the Project

The project has the purpose of creating a easy to use module to query and set autotask items.

I'm doing the project as a hobby, that means I might not always get time to react to issues, bugs, or pull requests. Feel free to message me directly on other platforms if I haven't replied in some time.

## Project Status

Current we are gearing up for release! Version 0.8.1 is already fully functional and the candidate to upgrade to 1.0. Currently there still is some expermentation going on with getting child items, and getting the body to allow dynamic parameters.

# Getting Started

So, if you want to help, I accept pull requests, and direct contributors, just send me a message!

There are not a lot of conditions but I do expect the following:

* Check your own code on multiple machines. We are targeting PowerShell 5.0+ though so keep that in mind.
* Both the installation of the module and execution of code will have to be "fast". For this I've set hard times: if the module load takes longer than 1 minute, the PR will have to be discussed before hand. If the loading takes longer than 3 minutes the PR will be denied.
* Code optimizing in encouraged, even if they might introduce minor bugs. If you think you introduce a minor bug, make a bug report and we can work on it together.
* currently we have two branches: Beta and Master. Master should always be the version published to the PsGallery.
