# CSGO-BAN-TIME-MANAGER

1. ###### Purpose

   This Software was created to easily keep track of cheaters in csgo by automatically fetching the relevant data for each suspect cheater from the steam API.

2. ###### Intention

   This Software is intended for private, non-commercial use only. It should not encourage miss-behavior on the csgo network or any other Valve-Related Software.

3. ###### Setup

   To install this software simply clone the repository and make sure you have the following perl modules installed:
    1. Dancer2
    2. Dancer2::Plugin::Auth::Extensible
    3. Dancer2::Plugin::Database
    4. DBD::SQLite

   Alternatively there you can build a docker image from the included Dockerfile. After building the image (this can take a while depending on a few factors such as your internet speed) you can start a new container with the following command:

   ``` docker run --rm -it -p 3001:5000 -v $(pwd):/opt dancer ```

   This will map the current working directory to the /opt folder inside the container. As well as it will make the application accesible through port 3001 of the machine running the container. Feel free to adjust these values to your needs.
