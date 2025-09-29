#!/bin/bash

sonar-scanner \
  -Dsonar.projectKey=Nuxt-WebNovaWp \
  -Dsonar.sources=. \
  -Dsonar.host.url=https://sonar.webnovawp.com \
  -Dsonar.login=sqp_5f26c63eeae45aa0b06f61889c6b6f34ae24b0fd
