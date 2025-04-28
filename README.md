DIRECTORIES:
ARTIFICIAL -- code for our artificial pipeline, with measurementmatrix.m that has our manually created measurement matrix
IMAGES -- images for our artificial dataset, and an apple dataset we used for testing earlier in the project
REALISTIC -- realistic dataset (box.mp4) and code for the realistic pipeline
TESTING -- old code from earlier in the project that we used for testing various approaches

ARTIFICIAL PIPELINE:

Corner detection:
![image](https://github.com/user-attachments/assets/ebd96449-8ce4-4fa7-ab46-5cdd3564c4b8)

In order to recreate this output, go into the Artificial directory in the code repository.
Then run the cornerdetection.m file. The resulting MATLAB plot should look like the image above.

![Screenshot 2025-04-28 014144](https://github.com/user-attachments/assets/f6eba504-df3c-4700-b620-0a2291170f3f)

In order to recreate this output, go into the Artificial directory in the code repository.
Then run the tomasi_kanade.m file. The resulting MATLAB 3D plot with the point cloud should look like the image above.




REALISTIC PIPELINE: 
![image](https://github.com/user-attachments/assets/1367ce31-515d-4878-abb4-b5571e0c0f5d)

In order to recreate this output, go into the Realistic directory in the code repository. 
Then run the preprocessing.m file before running the pipeline.m file. This should result in a folder of enhanced images as well as the 3D point cloud. 
