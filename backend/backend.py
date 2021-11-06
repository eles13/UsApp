from fastapi import FastAPI, Form
from pydantic import BaseModel
import torch
import uvicorn
from PIL import Image
import base64
import re
import numpy as np
import detectron2
import os, json, cv2, random
from pymongo import MongoClient
from detectron2 import model_zoo
from detectron2.engine import DefaultPredictor
from detectron2.config import get_cfg
from detectron2.utils.visualizer import Visualizer
from detectron2.data import MetadataCatalog, DatasetCatalog
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

origins = ["*"]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
mdb = MongoClient(os.environ['MONGODB_CONNSTRING'])
print(mdb.list_database_names())

cfg = get_cfg()
cfg.merge_from_file(model_zoo.get_config_file("COCO-InstanceSegmentation/mask_rcnn_R_50_FPN_3x.yaml"))
cfg.MODEL.ROI_HEADS.SCORE_THRESH_TEST = 0.5
cfg.MODEL.WEIGHTS = model_zoo.get_checkpoint_url("COCO-InstanceSegmentation/mask_rcnn_R_50_FPN_3x.yaml")
predictor = DefaultPredictor(cfg)

class ImageRequest(BaseModel):
    image: str
    name: str

def decode_base64(data, altchars='+/'):
    data = re.sub('[^a-zA-Z0-9%s]+' % altchars, '', data)
    missing_padding = len(data) % 4
    if missing_padding:
        data += '='* (4 - missing_padding)
    return base64.b64decode(data, altchars)

def preset_db():
    if 'usapp' not in mdb.list_database_names():
        mdb['usapp']
    if 'users' not in mdb['usapp'].list_collection_names():
        mdb['usapp'].create_collection('users')
    user = mdb.usapp.users.find_one({'uid': 'mainuser'})
    if not user:
        mdb.usapp.users.insert_one({'uid': 'mainuser', 'images': []})
    
def save_image(uid, image):
    mdb.usapp.users.update_one({'uid': uid}, {'$addToSet' : {'images': image}})
        
@app.post('/sendit')
async def receive_image(name: str = Form(...), image: str = Form(...)):
    with open('temp.jpg', 'wb') as fout:
        fout.write(decode_base64(image))
    im = cv2.imread("./temp.jpg")
    outputs = predictor(im)
    v = Visualizer(im[:, :, ::-1], MetadataCatalog.get(cfg.DATASETS.TRAIN[0]), scale=1.2)
    out = v.draw_instance_predictions(outputs["instances"].to("cpu"))
    cv2.imwrite('./temp_result.jpg', out.get_image()[:, :, ::-1])
    with open('./temp_result.jpg', 'rb') as fin:
        resimage = fin.read()
    resimage = base64.b64encode(resimage)
    save_image('mainuser', resimage)
    return {'status': 'success', 'result': resimage}

@app.get('/history')
def get_history():
    images = mdb.usapp.users.find_one({'uid': 'mainuser'})['images']
    return {'status': 'success', 'images': images}
    
if __name__ == '__main__':
    preset_db()
    uvicorn.run(app, host='0.0.0.0', port=8010)
