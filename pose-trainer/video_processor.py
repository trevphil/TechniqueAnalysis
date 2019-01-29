import cv2, shutil
from os import path, listdir, makedirs, remove
from PIL import Image
from moviepy.editor import VideoFileClip
from file_helper import *

class VideoProcessor:
    
    def __init__(self, labeled_data):
        prefix = './labeled/' if labeled_data else './unlabeled'
        self.labeled_data = labeled_data
        self.cache_dir = path.abspath(path.join(prefix, 'data/'))
        self.img_base = path.abspath(path.join(prefix, 'images/'))
        self.vid_base = path.abspath(path.join(prefix, 'videos/'))
        
    def _file_dir(self, file_path):
        # Returns the path to the directory that the file lives in
        i = file_path.rfind('/')
        return file_path[:i + 1]
        
    def _is_cached(self, video_path):
        name = filename_no_ext(video_path)
        return path.isfile(path.join(self.cache_dir, name + '.npy')) or \
            path.isfile(path.join(self.cache_dir, name + '_sec1.npy')) or \
            path.isfile(path.join(self.cache_dir, name + '_sec2.npy'))

    def _make_dir(self, directory_path):
        # Delete directory and all its contents if it exists
        if path.isdir(directory_path):
            shutil.rmtree(directory_path)
        # Make the directory
        makedirs(directory_path)
        
    def _skip_rate(self, file_path):
        filesize = path.getsize(file_path) / float(2 ** 10) # size in KB
        return 2 # Could increase the skip rate if the file size is large
        
    def _make_sections(self, video_path, section_len=3):
        # `section_len` is the number of seconds that each sample from the video should have
        name = filename_no_ext(video_path)
        ext = file_extension(video_path)
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
            sec_name = '{}_sec{}.{}'.format(name, idx + 1, ext)
            sec_path = path.join(self._file_dir(video_path), sec_name)
            subclip = clip.subclip(section[0], section[1])
            if file_extension(video_path) == 'mov':
                subclip.set_duration(section_len).write_videofile(sec_path,
                    fps=25, audio=False, verbose=False, progress_bar=False, codec='h264')
            else:
                subclip.set_duration(section_len).write_videofile(sec_path,
                    fps=25, audio=False, verbose=False, progress_bar=False)
            new_videos.append(sec_path)
        
        return new_videos

    def _video_as_images(self, video_path):
        # Directory containing images will be the same as the name of the video (minus extension)
        img_dir = path.join(self.img_base, filename_no_ext(video_path))
        self._make_dir(img_dir)
        
        vidcap = cv2.VideoCapture(video_path)
        success, image = vidcap.read()
        frame_num, i = (0, 0)
        skip_rate = self._skip_rate(video_path)
        
        while success:
            file_name = 'frame{}.jpg'.format(frame_num)
            p = path.join(img_dir, file_name)
            if i % skip_rate == 0:
                cv2.imwrite(p, image)
                frame_num += 1
            success, image = vidcap.read()
            i += 1
    
        return img_dir
    
    def _gif_as_images(self, gif_path):
        # Directory containing images will be the same as the name of the GIF (minus extension)
        img_dir = path.join(self.img_base, filename_no_ext(gif_path))
        self._make_dir(img_dir)
    
        frame_num, i = (0, 0)
        frame = Image.open(gif_path)
        skip_rate = self._skip_rate(video_path)
        
        while frame:
            p = path.join(img_dir, 'frame{}.png'.format(frame_num))
            if i % skip_rate == 0:
                frame.save(p)
                frame_num += 1
            i += 1
            try: frame.seek(i);
            except EOFError: break;
    
        return img_dir
    
    def generate_images(self, skip_cached=True):
        videos = []
        use_video = lambda v: is_video(v) and has_section(v) is False
        
        for f in [v for v in listdir(self.vid_base) if use_video(v)]:
            f = path.join(self.vid_base, f)
            
            if skip_cached and self._is_cached(f):
                continue
            
            if is_gif(f) or self.labeled_data is False:
                videos.append(f)
            else:
                sections = self._make_sections(f)
                videos += sections
    
        image_directories = []
        for vid in videos:
            img_dir = self._gif_as_images(vid) if is_gif(vid) else self._video_as_images(vid)
            image_directories.append(img_dir)
    
        return image_directories
    
    def cleanup(self):
        try: shutil.rmtree(self.img_base);
        except: pass;
        
        for vid_file in [v for v in listdir(self.vid_base) if has_section(v)]:
            remove(path.join(self.vid_base, vid_file))
