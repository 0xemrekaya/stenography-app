
# Steganography App

This is a steganography application built using Flutter, allowing you to encode and decode messages within images. The app supports both mobile and desktop platforms.

## Packages Used

- `crypto`: For hashing and cryptographic operations.
- `encrypt`: For encryption and decryption.
- `flex_color_scheme`: For theme customization.
- `image_picker`: For selecting images from the gallery.
- `image`: For image manipulation.
- `path_provider`: For accessing the file system.

## Usage

### Encode a Message

1. Pick an image from your device's gallery.
2. Enter the message you want to encode.
3. (Optional) Enable encryption by checking the checkbox and entering a key.
4. Click the "Encode and Save Image" button to encode the message into the image and save it.

### Decode a Message

1. Pick an image from your device's gallery that contains an encoded message.
2. (Optional) Enable decryption by checking the checkbox and entering the key used during encoding.
3. Click the "Decode Image" button to extract the message from the image.

## Features

- Encode messages into images.
- Decode messages from images.
- Option to encrypt messages with a key before encoding.
- Save the encoded image to the device.
- Supports both light and dark themes.

## Important Notes

- The length of the message to be encoded should be within the capacity of the image.
- If encryption is enabled, ensure that the same key is used for both encoding and decoding.
- The app displays a notification if the message length exceeds the capacity of the selected image.
- The app saves the encoded images in the application documents directory.


## Screenshots for Usage

### 1. Select an Image
First, you must select a image.

![image](https://github.com/0xemrekaya/stenography-app/assets/72754835/f4612576-eeb8-4161-b9f7-087cce3f9a2d)

### 2. Enter a Message
After selecting the image you have to enter a message text (optionally key can be entered) then click on the encode and save image button.

![image](https://github.com/0xemrekaya/stenography-app/assets/72754835/6cd1a7b6-02fd-406c-b062-5b9785e3da30)

### 3. Image Saved
After all, the steganographg image is saved your "documantation/steganography" director. And if you want decode the saved image, select it.

![image](https://github.com/0xemrekaya/stenography-app/assets/72754835/23262ee4-17b7-4e0b-93e0-5d5cf5e400e7)

### 4. Decoding the Image
If you do not provide the key (if the key is available), the message text shows the cipher text. If you have not previously given any key, the text is shown directly.

![image](https://github.com/0xemrekaya/stenography-app/assets/72754835/f2d56107-3e59-4747-adc3-ebb14db0293d)

### 5. Providing the Key
After giving the key, message text is showing.

![image](https://github.com/0xemrekaya/stenography-app/assets/72754835/3ffcfd92-de57-400e-a973-78f33ec983d7)


## License

This project is licensed under the MIT License.

