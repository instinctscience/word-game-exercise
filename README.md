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
- **Eliminate the slots and guesses tables.**
    - **Move this information into a jsonb `state` column on the games table.**

That’s what we’ll work on in the exercise! Fire up your notepad and editor. Let’s begin!

- What do you think of this approach?
- What steps would you take to implement this in a production environment? Please outline them.
- Let’s look at the code together and begin mocking up some of the initial changes.

Note: this code is an excerpt from our production codebase. It does not run, and tests have been excluded for simplicity.