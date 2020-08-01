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

   Alternatively there you can build a docker image from the included Dockerfile. To build the image, from the root directory of this repository run the following command:

   ``` docker build -t cbtm docker/. ```

   or use the script i provided wich is additionally going to measure the time it takes to build the image:

   ``` sudo ./build_docker_img.sh ```

   After building the image (this can take a while depending on a few factors such as your internet speed) you can start a new container with the following command:

   ``` docker run -d -it -p 3001:5000 cbtm ```

   This will map the application accessible through port 3001 of the machine running the container. Feel free to adjust these values to your needs. The container is going to run in the background.

   <details>
     <summary>Upgrading and migrating databases. Not yet implemented</summary>

    4. ###### Upgrading the application

       To upgrade the application you need to clone the repository again or use ```git pull``` to update the repository to the latest state. Then rebuild the docker image. Save the database from the old installation by going to the admin panel and clicking on the Upgrade Button and then on the Download Database Button. Make sure you save the database somewhere where you can access it later. Then stop and delete the old container and image, start a new container with the new image, and go to the usual setup steps. After that in the Upgrade Section in the admin panel there is a Upload Database Button. Click that and select your saved Database. **THIS WILL OVERRIDE THE 'NEW' DATABASE ENTIRELY.** Meaning that anything you configure in the new database will be lost. So make sure that users and other parameters are only changeg **AFTER** importing the old database.

</details>
