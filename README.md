# How to Build
## continuous integration and deployment
```
docker stop kerber;docker rm kerber;\
docker build --rm -t 'chorke/krb5:16.04' ./;\
docker rmi $(docker images -qa -f 'dangling=true');\
docker run --name='kerber' -d -p 9030:80 -p 389:389 chorke/krb5:16.04;\
docker exec -it kerber bash
```
## How to Create for first time to create container from docker image and shell access
```
docker run --name='kerber' -d -p 9030:80 -p 389:389 chorke/krb5:16.04
docker exec -it kerber bash
/root/.docker/init.sh
``