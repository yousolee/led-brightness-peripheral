-- LEDController.VHD
-- 2025.03.09
--
-- This SCOMP peripheral drives ten outputs high or low based on
-- a value from SCOMP.

LIBRARY IEEE;
LIBRARY LPM;

USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE LPM.LPM_COMPONENTS.ALL;

ENTITY LEDController IS
PORT(
    CS          : IN  STD_LOGIC;
    WRITE_EN    : IN  STD_LOGIC;
    RESETN      : IN  STD_LOGIC;
    LEDs        : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
     
    IO_DATA     : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
    CLOCK       : IN  STD_LOGIC
    );
END LEDController;

ARCHITECTURE a OF LEDController IS
    -- Using state bits directly instead of enumerated type
    -- state_bits(1 downto 0):
    -- "00" -> OFF
    -- "10" -> ON (with PWM brightness)
    -- "11" -> ON (with flashing and PWM brightness)
    -- "01" -> Undefined (treated as OFF)
    
    -- Arrays to track state and brightness of each LED
    TYPE led_state_array IS ARRAY (0 TO 9) OF STD_LOGIC_VECTOR(1 DOWNTO 0);
    TYPE led_brightness_array IS ARRAY (0 TO 9) OF INTEGER RANGE 0 TO 255;
    
    -- Signals for LED states and brightness levels
    SIGNAL led_states : led_state_array;
    SIGNAL led_brightness : led_brightness_array;
    
    -- Counters and timing signals
    SIGNAL pwm_counter : INTEGER RANGE 0 TO 255 := 0;
    SIGNAL flash_counter : INTEGER RANGE 0 TO 50000 := 0;
    SIGNAL flash_state : STD_LOGIC := '0';
    
    -- Register to hold LED output values
    SIGNAL led_outputs : STD_LOGIC_VECTOR(9 DOWNTO 0);
    
BEGIN
    -- Process to handle writes to the controller
    WRITE_PROCESS: PROCESS (RESETN, CS)
    BEGIN
        IF (RESETN = '0') THEN
            -- Initialize all LEDs to off state with zero brightness
            FOR i IN 0 TO 9 LOOP
                led_states(i) <= "00"; -- OFF state
                led_brightness(i) <= 0;
            END LOOP;

        ELSIF RISING_EDGE(CS) THEN
            IF WRITE_EN = '1' THEN
                -- Parse IO_DATA based on the provided format:
                -- [15:14] - State bits (see state definitions above)
                -- [13:10] - Brightness value (0-15)
                -- [9:0]   - LED mask (1 means update the corresponding LED)
                
                -- Extract the new state and brightness from IO_DATA
                FOR i IN 0 TO 9 LOOP
                    -- Only update LEDs for which the mask bit is set
                    IF IO_DATA(i) = '1' THEN
                        -- Update state based on bits [15:14]
                        led_states(i) <= IO_DATA(15 DOWNTO 14);
                        
                        -- Update brightness based on bits [13:10]
                        led_brightness(i) <= TO_INTEGER(UNSIGNED(IO_DATA(13 DOWNTO 10))*UNSIGNED(IO_DATA(13 DOWNTO 10)));
                    END IF;
                END LOOP;
            END IF;
        END IF;
    END PROCESS;
    
    -- Process to handle flashing
    FLASH_PROCESS: PROCESS (CLOCK)
    BEGIN
        IF RISING_EDGE(CLOCK) THEN
            IF flash_counter = 50000 THEN
                flash_counter <= 0;
                flash_state <= NOT flash_state;
            ELSE
                flash_counter <= flash_counter + 1;
            END IF;
        END IF;
    END PROCESS;
    
    -- Process to handle PWM counter
    PWM_PROCESS: PROCESS (CLOCK)
    BEGIN
        IF RISING_EDGE(CLOCK) THEN
            IF pwm_counter = 255 THEN
                pwm_counter <= 0;
            ELSE
                pwm_counter <= pwm_counter + 1;
            END IF;
        END IF;
    END PROCESS;
    
    -- Process to generate LED outputs based on states and brightness
    LED_OUTPUT_PROCESS: PROCESS (CLOCK)
    BEGIN
        IF RISING_EDGE(CLOCK) THEN
            FOR i IN 0 TO 9 LOOP
                CASE led_states(i) IS
                    WHEN "00" => -- OFF
                        led_outputs(i) <= '0';
                        
                    WHEN "10" => -- ON with PWM brightness
                        IF pwm_counter < led_brightness(i) THEN
                            led_outputs(i) <= '1';
                        ELSE
                            led_outputs(i) <= '0';
                        END IF;
                        
                    WHEN "11" => -- ON with flashing and PWM brightness
                        IF flash_state = '1' THEN
                            IF pwm_counter < led_brightness(i) THEN
                                led_outputs(i) <= '1';
                            ELSE
                                led_outputs(i) <= '0';
                            END IF;
                        ELSE
                            led_outputs(i) <= '0';
                        END IF;
                        
                    WHEN "01" => -- Undefined state (treated as OFF)
                        led_outputs(i) <= '0';
                        
                    WHEN OTHERS => -- Shouldn't happen, but safety first
                        led_outputs(i) <= '0';
                        
                END CASE;
            END LOOP;
        END IF;
    END PROCESS;
    
    -- Connect internal LED state to output pins
    LEDs <= led_outputs;
    
END a;
