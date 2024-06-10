import socket
import numpy as np
import cv2

def receive_image(sock: socket.socket) -> np.ndarray:
    '''
    Receives an image from the socket and returns it as a NumPy array, 
    ready to be displayed as an image. The image comes from a screen capture 
    of the DeSmuME emulator, using the Lua script:

    `C:/Users/lnick/Documents/Games/Lua/screenshot.lua`

    By continuously sending screenshots through the socket, the
    gameplay is effectively livestreamed through to OpenCV.
    
    ### Arguments
    #### Required
    - `sock` (socket.socket): socket object to receive image data from
    
    ### Returns
    - `np.ndarray`: image data as a NumPy array
    '''
    # Receive the length of the image data
    length_str = sock.recv(9)  # data length (9 bytes)
    if not length_str:
        return None
    data_length = int(length_str)

    # Receive the actual image data
    data = b''
    while len(data) < data_length:
        packet = sock.recv(data_length - len(data))
        if not packet:
            return None
        data += packet

    # Convert the image data to a NumPy array and then to an OpenCV image
    image = np.frombuffer(data, dtype=np.uint8)
    image = cv2.imdecode(image, cv2.IMREAD_COLOR)
    return image

def process_image(img: np.ndarray) -> np.ndarray:
    # for now, just return the image as is
    return img

def compute_button_input(img: np.ndarray) -> int:
    # output format: one byte representing the button inputs
    # 0 if button is not pressed, 1 if button is pressed
    # order: A, Left, Right, Unused, Unused, Unused, Unused, Unused
    # for now, just press and hold the A button (drive forward in Mario Kart)
    return 0b10000000

def send_buttons(sock: socket.socket, buttons: int) -> None:
    '''
    Sends a byte of button input data to the socket, which will be read by the
    Lua script controlling the DeSmuME emulator. The byte is formatted as follows:

    - Bit 0: A button
    - Bit 1: Left button
    - Bit 2: Right button
    - Bits 3-7: Unused

    ### Arguments
    #### Required
    - `sock` (socket.socket): socket object to send button data to
    - `buttons` (int): byte of button input data
    '''
    data = buttons.to_bytes(1, byteorder='big')
    sock.sendall(data)


# Set up the server using TCP IPv4
host, port = "127.0.0.1", 12345
server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.bind((host, port))

while cv2.waitKey(1) != ord('q'):  # loop for accepting connections, press 'q' to quit

    # wait for a connection
    server.listen(1)
    print(f"Listening for connections on {host}:{port}...")
    client_socket, client_address = server.accept()
    print(f"Connection from {client_address}.")

    while cv2.waitKey(1) != ord('q'):  # loop for processing image frames, press 'q' to quit
        image = receive_image(client_socket)
        if image is not None:
            proc_img = process_image(image)
            button_input = compute_button_input(proc_img)
            send_buttons(client_socket, button_input)
            cv2.imshow('Stream from DeSmuME', image)
        else:
            print('Failed to receive image. Closing connection.')
            break
    else:
        print('Quit key pressed. Closing connection and server.')
        cv2.destroyAllWindows()
        break

print('Closing server.')
client_socket.close()
server.close()
