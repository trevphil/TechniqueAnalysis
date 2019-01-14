from os import path, listdir
import numpy as np
from tqdm import tqdm

from video_processor import VideoProcessor
from feature_extractor import extract_features, OUTPUT_SHAPE
from knn_dtw import KnnDtw
from visualizer import animate

def _load_cache(cache_dir):
    cache = {}
    is_numpy_data = lambda f: len(f.split('.')) > 1 and f.split('.')[-1].lower() == 'npy'
    
    for data_file in [path.join(cache_dir, f) for f in listdir(cache_dir) if is_numpy_data(f)]:
        cached = np.load(data_file)
        label = data_file.split('/')[-1].split('.')[0]
        cache[label] = cached
    
    return cache
    
def _generate_timeseries(img_set):
    is_img = lambda f: len(f.split('.')) > 1 and f.split('.')[-1].lower() in ['jpg', 'jpeg', 'png']
    frame_num = lambda x: int(x[x.rfind('_') + 1:].split('.')[0])
    
    label = img_set.split('/')[-1]
    images = sorted([path.join(img_set, f) for f in listdir(img_set) if is_img(f)], key=frame_num)
    timeseries_shape = (len(images), ) + OUTPUT_SHAPE
    timeseries = np.zeros(timeseries_shape)
    
    desc = 'Processing images for "{}"'.format(label)
    for i in tqdm(range(len(images)), desc=desc, bar_format='{l_bar}{bar}'):
        img = images[i]
        heatmap = extract_features(img)
        timeseries[i] = heatmap
        
    return (label, timeseries)
    
def _create_data(labeled, skip_cached=True, include_reflection=False):
    vp = VideoProcessor(labeled_data=labeled)
    image_directories = vp.generate_images(skip_cached=skip_cached)
    if len(image_directories) == 0:
        print('INFO: No images were generated. Either none were provided, or the data is already cached.')

    data = _load_cache(vp.cache_dir)
    if len(data) > 0:
        print('INFO: The following items have been loaded from a saved state: {}'
            .format(', '.join(data.keys())))
    
    try:
        for img_dir in image_directories:
            name, timeseries = _generate_timeseries(img_dir)
            print('\nINFO: Saving timeseries for "{}"\n'.format(name))
            np.save(path.join(vp.cache_dir, '{}.npy'.format(name)), timeseries)
            data[name] = timeseries
    finally:
        vp.cleanup()
        
    if include_reflection:
        # Add the reflection across the y-axis for each time series, for more robustness
        reflected = {}
        for label, series in data.iteritems():
            reflected[label + '_reflected'] = np.flip(series, axis=2)
        data.update(reflected)
    
    return data

# TODO
# - Should there be an inverse relationship between confidence and distance?
# - Need some way to discount frames where the confidence of a body part's location is low for one of
#       the series. Cannot simply do (Euclidean dist / confidence) because it will cause the distance
#       to blow up for a comparison, causing the comparison to not be selected. Better to ignore the frame.
# - How should the warping window be set? http://alumni.cs.ucr.edu/~xxi/495.pdf
# - Should we only care about certain body parts, e.g. head + hips + hands + feet ?

if __name__ == '__main__':
    labeled_items = _create_data(True, include_reflection=True)
    unlabeled_items = _create_data(False)
    
    algo = KnnDtw(warping_window=1000)
    
    def remove_section_suffix(string):
        sec_suffix = string.rfind('-section')
        return string if sec_suffix == -1 else string[:sec_suffix]
    
    for unknown, unlabeled_series in unlabeled_items.iteritems():
        guess, score = algo.nearest_neighbor(labeled_items, unlabeled_series)
        guess = remove_section_suffix(guess)
        print('Best guess for {} is {} (score={:.1f})'.format(unknown, guess, score))
