import os, cv2
import tensorflow.python.platform
import tensorflow as tf

os.environ['CUDA_VISIBLE_DEVICES'] = ''
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2'

MODEL = 'model.pb'
INPUT_SHAPE = (192, 192)
OUTPUT_SHAPE = (96, 96, 14)
OUTPUT_NODES = 'Convolutional_Pose_Machine/stage_5_out'

with tf.gfile.GFile(MODEL, "rb") as f:
    graph_def = tf.GraphDef()
    graph_def.ParseFromString(f.read())

tf.import_graph_def(graph_def, input_map=None, return_elements=None, name='')

graph = tf.get_default_graph()
image = graph.get_tensor_by_name('image:0')
output = graph.get_tensor_by_name('%s:0' % OUTPUT_NODES)

def extract_features(img_path):
    image_0 = cv2.imread(img_path)
    assert image_0 is not None
    
    image_ = cv2.resize(image_0, INPUT_SHAPE, interpolation=cv2.INTER_AREA)

    with tf.Session() as sess:
        heatmap = sess.run(output, feed_dict={ image: [image_] })[0, :, :, :]
        """
        Produces a numpy array with shape (96, 96, 14)
        So, heatmap of body part 0 (head) on a 96x96 grid is given from `heatmap[:, :, 0]`
            ...
        All the way to body part 13 (left foot) - `heatmap[:, :, 13]`
        """
        return heatmap
