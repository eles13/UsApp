FROM nvidia/cuda:11.1.1-cudnn8-devel-ubuntu18.04
RUN apt-get update && apt-get install --no-install-recommends --no-install-suggests -y curl

RUN apt-get -y install python3.8
RUN apt-get -y install python3-pip
RUN apt-get -y install zip
RUN python3.8 -V

ENV DEBIAN_FRONTEND noninteractive


ENV TZ=Europe/Moscow
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update &&\
    apt-get install -y\
    bash\
    build-essential\
    gcc\
    libffi-dev\
    musl-dev\
    openssl\
    libpq-dev\
    libxml2\
    git

RUN ln -sv /usr/bin/python3 /usr/bin/python


RUN python3 -m pip install -U --force-reinstall pip

RUN pip3 install --user torch==1.10 torchvision==0.11.1 -f https://download.pytorch.org/whl/cu111/torch_stable.html
RUN git clone https://github.com/facebookresearch/detectron2.git
RUN python3 -m pip install -e detectron2
RUN apt-get update
RUN apt-get install ffmpeg libsm6 libxext6  -y
COPY requirements.txt ./requirements.txt
RUN pip3 install -r ./requirements.txt
COPY ./backend.py ./backend.py

ENTRYPOINT python3 ./backend.py
