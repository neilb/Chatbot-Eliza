# Chatbot-Eliza

[![Build Status](https://travis-ci.org/ggruen/Chatbot-Eliza.svg?branch=master)](https://travis-ci.org/ggruen/Chatbot-Eliza)

# NAME

Chatbot::Eliza - A clone of the classic Eliza program

# SYNOPSIS
     use Chatbot::Eliza;

     $mybot = new Chatbot::Eliza;
     $mybot->command_interface;

# INSTALLATION

## The easy way

cpanm Chatbot::Eliza

## From GitHub

Clone this repo, then:

    cpanm Dist::Zilla && dzil authordeps --missing | cpanm
    dzil install

# DEVELOPMENT

This module is built using Dist::Zilla.  Here are some basics:

Build and run tests:

    dzil test

If I got bored and you're a maintainer on CPAN, upload a release:

    dzil release

To see all the commands you can use with `dzil`:

    dzil commands

Learn more about updating dist.ini:

    man Dist::Zilla
