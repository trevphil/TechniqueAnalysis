import numpy as np
import sys

class KnnDtw:
    
    def __init__(self, warping_window):
        self.warping_window = warping_window

    def _dist(self, grid_a, grid_b):
        (max_row_a, max_col_a) = np.unravel_index(grid_a.argmax(), grid_a.shape)
        # confidence_a = max(grid_a[max_row_a, max_col_a], 1e-3)
        (max_row_b, max_col_b) = np.unravel_index(grid_b.argmax(), grid_b.shape)
        # confidence_b = max(grid_b[max_row_b, max_col_b], 1e-3)
    
        euclidean_dist = ((max_row_b - max_row_a) ** 2 + (max_col_b - max_col_a) ** 2) ** 0.5
        
        return euclidean_dist # / min(confidence_a, confidence_b)
    
    def _dtw_distance(self, timeseries_a, timeseries_b):
        m, n = timeseries_a.shape[0], timeseries_b.shape[0]
        cost = sys.maxint * np.ones((m, n))

        # Initialize the first row and column
        cost[0, 0] = self._dist(timeseries_a[0, :, :], timeseries_b[0, :, :])
        for i in xrange(1, m):
            cost[i, 0] = cost[i - 1, 0] + self._dist(timeseries_a[i, :, :], timeseries_b[0, :, :])

        for j in xrange(1, n):
            cost[0, j] = cost[0, j - 1] + self._dist(timeseries_a[0, :, :], timeseries_b[j, :, :])

        # Populate rest of cost matrix within the warping window's bounds
        for i in xrange(1, m):
            for j in xrange(max(1, i - self.warping_window),
                            min(n, i + self.warping_window)):
                choices = cost[i - 1, j - 1], cost[i, j - 1], cost[i - 1, j]
                cost[i, j] = min(choices) + self._dist(timeseries_a[i, :, :], timeseries_b[j, :, :])

        return cost[-1, -1]
    
    def dtw_distance(self, data_a, data_b):
        # `data_a` and `data_b` should each have shape (X, 96, 96, 14) where
        # X can be different for each array, and each value in 1...X represents a point in time.
    
        # The last element of `shape` should be the same for both, because the timeseries
        # should have the same number of body parts being compared (e.g. 14 body parts)
        assert data_a.shape[-1] == data_a.shape[-1]
    
        total_dist = 0
        for body_point in xrange(data_a.shape[-1]):
            body_point_dist = self._dtw_distance(data_a[:, :, :, body_point],
                                                 data_b[:, :, :, body_point])
            total_dist += body_point_dist
    
        return total_dist
        
    def nearest_neighbor(self, labeled_items, unlabeled_series):
        best_score, guess = sys.maxint, None
        for label, labeled_series in labeled_items.iteritems():
            score = self.dtw_distance(labeled_series, unlabeled_series)
            if score < best_score:
                # Lower score means there's a closer match between the two time series
                best_score = score
                guess = label
        return (guess, best_score)
    