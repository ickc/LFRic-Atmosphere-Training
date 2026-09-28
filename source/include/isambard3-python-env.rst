.. Re-usable chunk: activate the Python analysis environment on Isambard 3.
.. The environment version is pinned here only. It is built from
.. etc/isambard3/environment.yml by etc/isambard3/build-python-env.sh.
.. To use it: .. include:: /include/isambard3-python-env.rst

.. code-block:: bash

   LFRIC_TRAINING_CONDA=/projects/u35v/khcheung.u35v/opt/Linux-aarch64/conda
   eval "$("$LFRIC_TRAINING_CONDA/bin/micromamba" shell hook --shell bash)"
   micromamba activate "$LFRIC_TRAINING_CONDA/envs/lfric-training-v2026.09.28"
