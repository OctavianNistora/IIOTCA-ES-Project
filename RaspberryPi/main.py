from math import nan
from multiprocessing import Process, Pipe
from time import sleep

from sympy import sec

def proximity_sensor(input, output): # Function to measure the distance between the sensor and an object
    import gpiod # Import the GPIO library used to interact with the GPIO pins
    import time # Import the time library used for delays
    try:
        chip = gpiod.Chip('gpiochip4') # Initialize the GPIO chip

        transmit_pin = 23 # Transmit pin of the ultrasonic sensor
        transmit_line = chip.get_line(transmit_pin) # Get the transmit line
        transmit_line.request(consumer = "Trigger", type = gpiod.LINE_REQ_DIR_OUT) # Request the transmit line

        receive_pin = 24 # Receive pin of the ultrasonic sensor
        receive_line = chip.get_line(receive_pin) # Get the receive line
        receive_line.request(consumer = "Echo", type = gpiod.LINE_REQ_DIR_IN) # Request the receive line

        speed_SI = 0 # Speed of observer/vehicle in SI units

        while(True): # Infinite loop to continuously measure the distance
            while (input.poll()): # Parse the input buffer until it is empty
                speed_SI = float(input.recv()) # Receive the next speed value from the main process in SI units (if available)

            transmit_line.set_value(1) # Transmit the soundwaves
            transmit_line.set_value(0) # Stop transmitting the soundwaves

            stop = time.time() # Set the time of transmission
            start = time.time() # Set the time of transmission
            while receive_line.get_value() == 0: # Wait for the soundwaves to be received
                start = time.time() # Set the time of reception
                if (start - stop) > 0.1: # If the delay is too long, stop waiting
                    break
            if (start - stop) > 0.1: # If the delay is too long, skip the rest of the loop and start again
                continue

            stop = start # Set the time of no reception as the time of reception
            while  receive_line.get_value() == 1: # Wait for the soundwaves to stop being received
                stop = time.time() # Set the time of no reception
            if stop == start: # If the soundwaves were not received in time, skip the rest of the loop and start again
                continue

            duration = stop - start # Calculate the time taken for the soundwaves to be received
            distance = (343 - speed_SI) * (duration / 2) # Calculate the distance between the sensor and the object in meters while accounting for the speed of the observer/vehicle
            output.send(distance) # Send the distance to the main process
            time.sleep(0.1) # Wait for 0.1 seconds before starting the next iteration to prevent the process from consuming too much CPU power and becoming unstable
    except:
        if 'receive_line' in locals(): # Check if the receive line exists
            receive_line.release() # Release the receive line
        if 'transmit_line' in locals(): # Check if the transmit line exists
            transmit_line.release() # Release the transmit line
        if 'chip' in locals(): # Check if the GPIO chip exists
            chip.close() # Close the GPIO chip
        input.close() # Close the input pipe
        output.close() # Close the output pipe
        print("Proximity Sensor Process Ended") # Print a message to indicate that the proximity sensor process has ended

def dc_motor(input): # Function to control the speed and direction of a DC motor
    import gpiod # Import the GPIO library used to interact with the GPIO pins
    import time # Import the time library used for delays

    def safe_write(file, value): # Function to safely write to a file
        with open(file, 'w') as f:
            f.write(value)

    try:
        period = 5000000 # Period of the PWM signal in nanoseconds
        speed = 0 # Speed of the DC motor ranging from -1 to 1 (negative values for reverse, 0 for stop, and positive values for forward)
        chip = gpiod.Chip('gpiochip4') # Initialize the GPIO chip (gpiochip4 for Raspberry Pi 5 and gpiochip2 for older Raspberry Pi models)

        try: # Try to activate the PWM chip
            safe_write("/sys/class/pwm/pwmchip2/export", "0") # Activate the PWM chip (pwmchip2 for Raspberry Pi 5 and pwmchip0 for older Raspberry Pi models)
        except: # If the PWM chip is already activated, ignore the error
            pass
        time.sleep(0.1) # Wait for 0.1 seconds to allow the PWM chip to be activated
        try: # Try to set the period of the PWM signal
            safe_write("/sys/class/pwm/pwmchip2/pwm0/period", f"{period}\n") # Set the period of the PWM signal
        except: # If the duty cycle is not set or was set with a higher value than the period, ignore the error
            pass 
        time.sleep(0.1) # Wait for 0.1 seconds to allow the period to be set
        safe_write("/sys/class/pwm/pwmchip2/pwm0/duty_cycle", "0\n") # Set the duty cycle of the PWM signal
        time.sleep(0.1) # Wait for 0.1 seconds to allow the duty cycle to be set
        safe_write("/sys/class/pwm/pwmchip2/pwm0/period", f"{period}\n") # Make sure the period is set
        time.sleep(0.1) # Wait for 0.1 seconds to allow the period to be set
        safe_write("/sys/class/pwm/pwmchip2/pwm0/enable", "1\n") # Enable the PWM signal


        first_pin = 15 # First pin of the DC motor
        first_line = chip.get_line(first_pin) # Get the first line
        first_line.request(consumer = "DC_FIRST", type = gpiod.LINE_REQ_DIR_OUT) # Request the first line

        second_pin = 25 # Second pin of the DC motor
        second_line = chip.get_line(second_pin) # Get the second line
        second_line.request(consumer = "DC_SECOND", type = gpiod.LINE_REQ_DIR_OUT) # Request the second line

        while True:
            while (input.poll()): # Parse the input buffer until it is empty
                speed = input.recv() # Receive the next speed value from the main process
            if (speed > 0): # Rotate the DC motor in the forward direction
                second_line.set_value(0) 
                first_line.set_value(1)
                safe_write("/sys/class/pwm/pwmchip2/pwm0/duty_cycle", f"{int(speed * period)}\n") # Adjust the duty cycle of the PWM signal to control the speed of the DC motor
            elif (speed < 0): # Rotate the DC motor in the reverse direction
                first_line.set_value(0)
                second_line.set_value(1)
                safe_write("/sys/class/pwm/pwmchip2/pwm0/duty_cycle", f"{int(-speed * period)}\n") # Adjust the duty cycle of the PWM signal to control the speed of the DC motor
            else: # Stop the rotation of the DC motor
                first_line.set_value(0)
                second_line.set_value(0)
    except:
        safe_write("/sys/class/pwm/pwmchip2/unexport", "0") # Deactivate the PWM chip
        first_line.set_value(0) # Stop the rotation of the DC motor
        second_line.set_value(0) 
        first_line.release() # Release the transmit line
        second_line.release() # Release the receive line
        print("DC Motor Process Ended")

def object_detection_camera(output): # Function to detect objects in the camera feed
    from ultralytics import YOLO # Import the YOLO library used for object detection
    from picamera2 import Picamera2 # Import the Picamera2 library used to interact with the Raspberry Pi camera

    model = YOLO("best.onnx") # Load the YOLO model
    picam2 = Picamera2() # Initialize the Raspberry Pi camera
    picam2.configure(picam2.create_preview_configuration(main={"format": 'RGB888', "size": (640, 480)})) # Configure the camera preview
    picam2.start() # Start the camera preview
    while(True): # Infinite loop to continuously detect objects in the camera feed
        frame = picam2.capture_array() # Capture a frame from the camera feed

        results = model(frame, imgsz=480, verbose=False) # Detect objects in the frame

        signs_list = [] # List to store the detected objects
        for box in results[0].boxes: # Iterate over the detected objects
            class_id = box.cls # Get the class ID of the detected object
            signs_list += [model.names[int(class_id)]] # Get the class name of the detected object and add it to the list of detected objects
            # Sign names are kept as they are in order to preserve as much information as possible
        output.send(signs_list) # Send the list of detected objects to the main process

def accelerometer_sensor_process(output): # Function to measure the acceleration in the x, y, and z directions
    import smbus # Import the smbus library used to interact with the I2C bus
    import time # Import the time library used for delays
    
    DEVICE_ADDRESS	= 0x68 # I2C address of the MPU6050 sensor
    SMPLRT_DIV		= 0x19 # Address of Sample Rate Divider register
    CONFIG			= 0x1A # Address of Configuration register
    ACCEL_CONFIG	= 0x1C # Address of Accelerometer Configuration register
    ACCEL_XOUT_H	= 0x3B # Address of X-axis Acceleration Data register
    ACCEL_YOUT_H	= 0x3D # Address of Y-axis Acceleration Data register
    ACCEL_ZOUT_H	= 0x3F # Address of Z-axis Acceleration Data register
    PWR_MGMT_1		= 0x6B # Address of Power Management 1 register
    PWR_MGMT_2		= 0x6C # Address of Power Management 2 register
    
    def init_mpu(bus, device_address): # Function to initialize the MPU6050 sensor
        bus.write_byte_data(device_address, SMPLRT_DIV, 0x07) # Set the sample rate divider to 7
        bus.write_byte_data(device_address, CONFIG, 0x00) # Set the digital low pass filter to 0 and disable the external frame synchronization
        bus.write_byte_data(device_address, ACCEL_CONFIG, 0x08) # Set the full scale range of the accelerometer to ±4g
        bus.write_byte_data(device_address, PWR_MGMT_1, 0x0C) # Disable the temperature sensor and set the clock source to the external 32.768 kHz oscillator
        bus.write_byte_data(device_address, PWR_MGMT_2, 0x07) # Set the gyroscope sensors (X, Y and Z axes) in standby mode
    
    def read_data_register(bus, device_address, address): # Function to read the data from a register
        high = bus.read_byte_data(device_address, address) # Read the high byte
        low = bus.read_byte_data(device_address, address+1) # Read the low byte

        value = ((high << 8) | low) # Combine the high and low bytes

        if(value > 32768): # Convert the unsigned value to a signed value (if necessary)
            value = value - 65536
        return value # Return the signed value
    
    try: # Try to read the acceleration data from the MPU6050 sensor
        bus = smbus.SMBus(1) # Initialize the I2C bus
        init_mpu(bus, DEVICE_ADDRESS) # Initialize the MPU6050 sensor
        LSBg = 16384.0 / (((bus.read_byte_data(DEVICE_ADDRESS, ACCEL_CONFIG) >> 3) & 0x03) + 1) # Calculate the LSB sensitivity of the accelerometer

        while True: # Infinite loop to continuously measure the acceleration
            try:
                acc_x = read_data_register(bus, DEVICE_ADDRESS, ACCEL_XOUT_H) # Read the acceleration in the x direction
                acc_y = read_data_register(bus, DEVICE_ADDRESS, ACCEL_YOUT_H) # Read the acceleration in the y direction
                acc_z = read_data_register(bus, DEVICE_ADDRESS, ACCEL_ZOUT_H) # Read the acceleration in the z direction
            except IOError: # If there is an I/O error caused by the CPU being too busy, skip the rest of the loop and start again
                continue
            except: # If there is any other error, raise the error to stop the process
                raise

            Ax = acc_x/LSBg # Convert the raw acceleration data to g-force
            Ay = acc_y/LSBg # Convert the raw acceleration data to g-force
            Az = acc_z/LSBg # Convert the raw acceleration data to g-force
            output.send([Ax, Ay, Az]) # Send the acceleration data to the main process
            time.sleep(0.01) # Wait for 0.01 seconds before starting the next iteration to prevent the process from consuming too much CPU power and becoming unstable
    except: # If there is an error, close the I2C bus and the output pipe
        bus.close() # Close the I2C bus
        output.close() # Close the output pipe
        print("Accelerometer Process Ended")

if __name__ == "__main__":
    from math import nan
    parent_proximity_input, child_proximity_output = Pipe(False) # Create a pipe from the proximity sensor process to the main process
    child_proximity_input, parent_proximity_output = Pipe(False) # Create a pipe from the main process to the proximity sensor process
    proximity_sensor_process = Process(target=proximity_sensor, args=(child_proximity_input, child_proximity_output)) # Create a process for the proximity sensor
    proximity_sensor_process.start() # Start the proximity sensor process

    child_motor_input, parent_motor_output = Pipe(False) # Create a pipe from the main process to the DC motor process
    motor_process = Process(target=dc_motor, args=(child_motor_input,)) # Create a process for the DC motor
    motor_process.start() # Start the DC motor process

    parent_camera_input, child_camera_output = Pipe(False) # Create a pipe from the object detection process to the main process
    camera_process = Process(target=object_detection_camera, args=(child_camera_output,)) # Create a process for the object detection camera
    camera_process.start() # Start the object detection camera process

    parent_accelerometer_input, child_accelerometer_output = Pipe(False) # Create a pipe from the accelerometer process to the main process
    accelerometer_process = Process(target=accelerometer_sensor_process, args=(child_accelerometer_output,)) # Create a process for the accelerometer
    accelerometer_process.start() # Start the accelerometer process

    try:
        crashes = 0 # Variable to store the number of crashes
        stop_signs = ["regulatory - stop"] # List of signs that require the vehicle to stop
        reduce_signs = ["regulatory - yield", "warning - roadworks", "warning - children", "warning - pedestrians crossing", "warning - railroad crossing", "warning - railroad crossing with barriers", "warning - railroad crossing without barriers"] # List of signs that require the vehicle to reduce its speed

        while True: # Infinite loop to continuously control the speed of the DC motor based on the proximity sensor and the detected objects
            distance = nan # Variable to store the distance between the sensor and an object, initialized to NaN in case the proximity sensor process has not sent any data
            signs = [] # List to store the detected objects, initialized to an empty list in case the object detection camera process has not sent any data
            acceleration = [] # List to store the acceleration in the x, y, and z directions, initialized to an empty list in case the accelerometer process has not sent any data
            total_acceleration = 0 # Variable to store the total acceleration, initialized to 0 as the default acceleration in case the accelerometer process has not sent any data
            speed = 0.0 # Variable to store the speed of the DC motor, initialized to 0.0 as the default speed in case no other speed is set

            while (parent_proximity_input.poll()): # Parse the input buffer until it is empty
                distance = parent_proximity_input.recv() # Receive the next distance value from the proximity sensor process
            print(f"Distance: {distance}") # Print the distance between the sensor and an object for debugging purposes
            
            while (parent_camera_input.poll()): # Parse the input buffer until it is empty
                signs = parent_camera_input.recv() # Receive the next list of detected objects from the object detection camera process
            print(f"Signs: {signs}") # Print the detected objects for debugging purposes

            while (parent_accelerometer_input.poll()): # Parse the input buffer until it is empty
                acceleration = parent_accelerometer_input.recv() # Receive the next acceleration value from the accelerometer process
            print(f"Acceleration: {acceleration}") # Print the acceleration in the x, y, and z directions for debugging purposes

            for a in acceleration: # Calculate the total acceleration
                total_acceleration += a**2 # Add the square of each acceleration component to the total acceleration
            total_acceleration = total_acceleration**0.5 # Take the square root of the total acceleration
            print(f"Total Acceleration: {total_acceleration}") # Print the total acceleration for debugging purposes

            if total_acceleration > 1.2: # If the total acceleration is greater than 1.2 g, increment the number of crashes
                crashes += 1
            print(f"Crashes: {crashes}")

            if crashes == 0: # If no crash has occurred, control the speed of the DC motor based on the distance and the detected objects
                if distance < 0.5: # If the distance is less than 0.5 meters, go backwards at half speed
                    speed = -0.5
                elif distance > 1.0: # If the distance is greater than 1.0 meters, go forwards
                    if distance < 3.0: # If the distance is less than 3.0 meters, go at half speed
                        speed = 0.5
                    else: # If the distance is greater than 3.0 meters, go at full speed
                        speed = 1.0
                # No need for else statement as speed is already set to 0.0

                if any(' - '.join(sign.split('--')[:-1]) in stop_signs for sign in signs): # If a stop sign is detected, stop the vehicle
                    speed = 0.0
                elif any(' - '.join(sign.split('--')[:-1]) in reduce_signs for sign in signs): # If a yield or a warning sign is detected, slow down the vehicle
                    if speed > 0.0: # Slow down the vehicle if it is moving forwards
                        speed = 0.5
            else:
                speed = 0.0 # Stop the vehicle if a crash has occurred

            parent_motor_output.send(speed) # Send the speed of the DC motor to the DC motor process

            print() # Print an empty line to separate the iterations for debugging purposes
            sleep(0.4) # Wait for 0.4 seconds before starting the next iteration to prevent the process from consuming too much CPU power and becoming unstable
    except:
        parent_motor_output.close()
        parent_proximity_input.close() # Close the input pipe from the proximity sensor process
        parent_proximity_output.close() # Close the output pipe to the proximity sensor process
        proximity_sensor_process.join() # Wait for the proximity sensor process to end
        camera_process.kill() # Kill the object detection camera process
        parent_camera_input.close() # Close the input pipe from the object detection camera process
        print("Camera Process Killed") # Print a message to indicate that the object detection camera process has been killed
        print("Main Process Ended") # Print a message to indicate that the main process has ended

