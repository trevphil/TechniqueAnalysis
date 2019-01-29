
# VIDEO filename format
#
# exercise-name_angle_secX.ext
#     - exercise-name: any hyphenated name
#     - angle: front, back, side1, side2
#     - secX: sec1 or sec2
# Supported video formats are MP4, MOV, GIF

def without_path_prefix(f):
    return f.split('/')[-1]
    
def filename_no_ext(f):
    f = without_path_prefix(f)
    if len(f.split('.')) >= 2:
        return f.split('.')[-2]
    return f.split('.')[-1]
    
def file_extension(f):
    f = without_path_prefix(f)
    return f.split('.')[-1].lower()
    
def is_gif(f):
    return file_extension(f) == 'gif'

def is_img(f):
    f = without_path_prefix(f)
    return len(f.split('.')) > 1 and \
        f.split('.')[-1].lower() in ['jpg', 'jpeg', 'png']
    
def is_video(f):
    f = without_path_prefix(f)
    return len(f.split('.')) > 1 and \
        f.split('.')[-1].lower() in ['mp4', 'mov', 'gif']
        
def is_numpy_data(f):
    f = without_path_prefix(f)
    return len(f.split('.')) > 1 and f.split('.')[-1].lower() == 'npy'

def camera_angle(f):
    f = without_path_prefix(f)
    parts = f.split('_')
    assert len(parts) > 1, 'Cannot determine camera angle from {}'.format(f)
    error_msg = '{} is not a valid camera angle!'.format(parts[1])
    assert parts[1] in ['front', 'back', 'side1', 'side2'], error_msg
    return parts[1]
    
def has_section(f):
    f = filename_no_ext(f)
    return ('_sec1' in f) or ('_sec2' in f)
    
def section(f):
    f = filename_no_ext(f)
    parts = f.split('_')
    assert len(parts) > 2, 'Cannot determine section number from {}'.format(f)
    assert parts[2] in ['sec1', 'sec2'], '{} is not a valid section!'.format(parts[2])
    return parts[2]
    
def unique_id(f):
    f = without_path_prefix(f)
    return '{}_{}_{}'.format(f.split('_')[0],
                             camera_angle(f),
                             section(f) if has_section(f) else 'sec1')
    
def frame_number(f):
    f = without_path_prefix(f)
    f = filename_no_ext(f)
    return int(f.replace('frame', ''))
    
def exercise_name_and_angle(label):
    return '{}_{}'.format(label.split('_')[0], camera_angle(label))
    
def opposite_side(label):
    if label.rfind('side1') != -1:
        return label.replace('side1', 'side2')
    elif label.rfind('side2') != -1:
        return label.replace('side2', 'side1')
    else:
        assert False, '{} does not have an opposite side!'.format(label)
        return None
