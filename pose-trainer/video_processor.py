import cv2, shutil
from os import path, listdir, makedirs, remove
from PIL import Image
from moviepy.editor import VideoFileClip

class VideoProcessor:
    
    def __init__(self, labeled_data):
        prefix = './labeled/' if labeled_data else './unlabeled'
        self.cache_dir = path.abspath(path.join(prefix, 'data/'))
        self.img_base = path.abspath(path.join(prefix, 'images/'))
        self.vid_base = path.abspath(path.join(prefix, 'videos/'))
    
    def _file_name(self, file_path):
        # The name of the file, without the extension
        return file_path.split('/')[-1].split('.')[-2]
        
    def _file_ext(self, file_path):
        return file_path.split('.')[-1].lower()
        
    def _file_dir(self, file_path):
        # Returns the path to the directory that the file lives in
        i = file_path.rfind('/')
        return file_path[:i + 1]
    
    def _supported_file(self, f):
        return len(f.split('.')) > 1 and self._file_ext(f) in ['mp4', 'mov', 'gif']
    
    def _is_gif(self, f):
        return self._file_ext(f) == 'gif'
        
    def _is_cached(self, video_path):
        name = self._file_name(video_path)
        return path.isfile(path.join(self.cache_dir, name + '.npy'))

    def _make_dir(self, directory_path):
        # Delete directory and all its contents if it exists
        if path.isdir(directory_path):
            shutil.rmtree(directory_path)
        # Make the directory
        makedirs(directory_path)
        
    def _skip_rate(self, file_path):
        filesize = path.getsize(file_path) / (2 ** 10) # size in KB
        return 2 # Could increase the skip rate if the file size is large
        
    def _make_sections(self, video_path, section_len=3):
        # `section_len` is the number of seconds that each sample from the video should have
        name = self._file_name(video_path)
        ext = self._file_ext(video_path)
        sections = []
        clip = VideoFileClip(video_path)
        duration = clip.duration
        one_tenth = duration * 0.10
        
        if duration <= section_len:
            sections = [(0, duration)]
        elif duration < (section_len * 2) + (one_tenth * 2):
            sections = [(duration/2 - section_len/2, duration/2 + section_len/2)]
        else:
            sections = [
                (one_tenth, one_tenth + section_len),
                (duration - one_tenth - section_len, duration - one_tenth)
            ]
        
        new_videos = []
        for idx, section in enumerate(sections):
            sec_name = '{}-section{}.{}'.format(name, idx, ext)
            sec_path = path.join(self._file_dir(video_path), sec_name)
            subclip = clip.subclip(section[0], section[1])
            subclip.set_duration(section_len).write_videofile(sec_path,
                fps=15, audio=False, verbose=False, progress_bar=False)
            new_videos.append(sec_path)
        
        return new_videos

    def _video_as_images(self, video_path):
        # Directory containing images will be the same as the name of the video (minus extension)
        img_dir = path.join(self.img_base, self._file_name(video_path))
        self._make_dir(img_dir)
        
        vidcap = cv2.VideoCapture(video_path)
        success, image = vidcap.read()
        frame_num, i = (0, 0)
        skip_rate = self._skip_rate(video_path)
        
        while success:
            file_name = 'frame_{}.jpg'.format(frame_num)
            p = path.join(img_dir, file_name)
            if i % skip_rate == 0:
                cv2.imwrite(p, image)
                frame_num += 1
            success, image = vidcap.read()
            i += 1
    
        return img_dir
    
    def _gif_as_images(self, gif_path):
        # Directory containing images will be the same as the name of the GIF (minus extension)
        img_dir = path.join(self.img_base, self._file_name(gif_path))
        self._make_dir(img_dir)
    
        frame_num, i = (0, 0)
        frame = Image.open(gif_path)
        skip_rate = self._skip_rate(video_path)
        
        while frame:
            p = path.join(img_dir, 'frame_{}.png'.format(frame_num))
            if i % skip_rate == 0:
                frame.save(p)
                frame_num += 1
            i += 1
            try: frame.seek(i);
            except EOFError: break;
    
        return img_dir
    
    def generate_images(self, skip_cached=True):
        videos = []
        use_video = lambda v: self._supported_file(v) and self._file_name(v).rfind('-section') == -1
        
        for f in [v for v in listdir(self.vid_base) if use_video(v)]:
            f = path.join(self.vid_base, f)
            if self._is_gif(f):
                videos.append(f)
            else:
                sections = self._make_sections(f)
                videos += sections
        
        if skip_cached:
            videos = list(filter(lambda v: self._is_cached(v) is False, videos))
    
        image_directories = []
        for vid in videos:
            img_dir = self._gif_as_images(vid) if self._is_gif(vid) else self._video_as_images(vid)
            image_directories.append(img_dir)
    
        return image_directories
    
    def cleanup(self):
        try: shutil.rmtree(self.img_base);
        except: pass;
        
        should_delete = lambda f: self._file_name(f).rfind('-section') != -1
        for vid_file in [v for v in listdir(self.vid_base) if should_delete(v)]:
            remove(path.join(self.vid_base, vid_file))
