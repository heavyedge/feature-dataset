import unittest
from functools import partial

import numpy as np

from scripts.v1.bo_util import EI, LCB, select_next_idx


class SelectNextIdxTest(unittest.TestCase):
    def test_lcb_uses_argmin(self):
        acq = np.array([2.5, -1.0, 3.0])
        self.assertEqual(select_next_idx(acq, partial(LCB, kappa=1.0)), 1)

    def test_ei_uses_argmax(self):
        acq = np.array([0.5, 2.5, 1.0])
        self.assertEqual(select_next_idx(acq, EI), 1)


if __name__ == "__main__":
    unittest.main()
