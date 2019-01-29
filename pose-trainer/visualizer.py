from time import sleep

def animate(label, timeseries, scale=3, confidence_cutoff=0.5):
    try:
        import Tkinter as tk
    except ImportError:
        import tkinter as tk
    
    shape = timeseries.shape
    num_frames = shape[0]
    num_bodypoints = shape[-1]
    (rows, cols) = (shape[1], shape[2])
    
    master = tk.Tk()
    master.title(label)
    canvas = tk.Canvas(master, width=cols * scale, height=rows * scale)
    canvas.pack()
    
    for frame in xrange(num_frames):
        canvas.delete(tk.ALL)
        for bp in xrange(num_bodypoints):
            heatmap = timeseries[frame, :, :, bp]
            for y in xrange(rows):
                for x in xrange(cols):
                    val = heatmap[y, x]
                    if val > confidence_cutoff:
                        color = 'red' if bp % 2 == 0 else 'blue'
                        bounding_box = (x * scale, y * scale, x * scale + scale, y * scale + scale)
                        canvas.create_oval(bounding_box, width=1, fill=color, outline=color)
        master.update()
        sleep(0.1)
        if frame == num_frames - 1: master.destroy();
    master.mainloop()
