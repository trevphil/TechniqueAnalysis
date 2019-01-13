import cv2, shutil
from os import path, listdir, makedirs
from PIL import Image

class VideoProcessor:
    
    def __init__(self, labeled_data, reduce_size=True):
        prefix = './labeled/' if labeled_data else './unlabeled'
        self.labeled = labeled_data
        self.cache_dir = path.abspath(path.join(prefix, 'data/'))
        self.img_base = path.abspath(path.join(prefix, 'images/'))
        self.vid_base = path.abspath(path.join(prefix, 'videos/'))
        # `True` to reduce the number of generated images by half
        self.reduce_size = reduce_size
    
    def _supported_file(self, f):
        return len(f.split('.')) > 1 and f.split('.')[-1].lower() in ['mp4', 'mov', 'gif']
    
    def _is_gif(self, f):
        return f.split('.')[-1].lower() == 'gif'

    def _make_dir(self, directory_path):
        # Delete directory and all its contents if it exists
        if path.isdir(directory_path):
            shutil.rmtree(directory_path)
        # Make the directory
        makedirs(directory_path)

    def _video_as_images(self, video_path):
        # Directory containing images will be the same as the name of the video (minus extension)
        img_dir = path.join(self.img_base, video_path.split('.')[-2].split('/')[-1])
        self._make_dir(img_dir)
    
        vidcap = cv2.VideoCapture(video_path)
        success, image = vidcap.read()
        i = 0
        while success:
            file_name = 'frame_{}.jpg'.format(i)
            p = path.join(img_dir, file_name)
            if self.reduce_size == False or i % 2 == 0:
                cv2.imwrite(p, image)
            success, image = vidcap.read()
            i += 1
    
        return img_dir
    
    def _gif_as_images(self, gif_path):
        # Directory containing images will be the same as the name of the video (minus extension)
        img_dir = path.join(self.img_base, gif_path.split('.')[-2].split('/')[-1])
        self._make_dir(img_dir)
    
        i = 0
        frame = Image.open(gif_path)
        while frame:
            p = path.join(img_dir, 'frame_{}.png'.format(i))
            if self.reduce_size == False or i % 2 == 0:
                frame.save(p)
            i += 1
            try: frame.seek(i);
            except EOFError: break;
    
        return img_dir
    
    def generate_images(self, skip_cached=True):
        videos = [path.join(self.vid_base, f) for f in listdir(self.vid_base) if self._supported_file(f)]
    
        is_cached = lambda v: path.isfile(path.join(self.cache_dir,
            v.split('/')[-1].split('.')[0] + '.npy'))
        if skip_cached:
            videos = list(filter(lambda x: is_cached(x) is False, videos))
    
        image_directories = []
        for vid in videos:
            img_dir = self._gif_as_images(vid) if self._is_gif(vid) else self._video_as_images(vid)
            image_directories.append(img_dir)
    
        return image_directories
    
    def cleanup(self):
        try: shutil.rmtree(self.img_base);
        except: pass;
