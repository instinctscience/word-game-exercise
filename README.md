# SWE Interview Exercise: Word Game

## Introduction

Welcome to the Instinct Interview Exercise!

The goal of this exercise is to pair together to give both of us an example of working together on a real problem. This is not a test. Rather, it is an exercise that will be scored on collaboration, problem solving, and competence to implement an idea in a codebase.

To get started, let’s review the feature we will work on:

[**SWE Interview Exercise Presentation**](https://docs.google.com/presentation/d/1IcJBuyRc_tGDn6-LJmtNP0DdDSiW7I_uTn5ClYN7JCM/edit?usp=sharing)

## Mission

We would like to simplify the data model to only have two tables:

- **Keep the standard data templates table.**
- **Keep the games table.**
- **Move the slots and guesses information into a simple jsonb column on the “games” table.**

That’s what we’ll work on in the exercise! Fire up your notepad and editor. Let’s begin!

- Start with discussing a PLAN for implementing this change. Imagine you’re responsible for the project. How do we proceed?
- After that, let’s jump in and start coding the project.

Note: this code is an excerpt from our production codebase. It does not run, and tests have been excluded for simplicity.