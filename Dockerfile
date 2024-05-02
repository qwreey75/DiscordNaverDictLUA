FROM luna.moon:5000/luvit-runtime AS runner

ARG DEBIAN_FRONTEND=noninteractive
RUN apt update; apt upgrade -y
RUN apt install bash ffmpeg libopus-dev libsodium-dev -y
RUN apt install python3 nodejs npm -y
WORKDIR /app
ADD . /app
RUN npm i
CMD /app/run.sh

