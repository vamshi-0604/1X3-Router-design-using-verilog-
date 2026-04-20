Project Overview: 1×3 Packet Router Design
Technical Specification & Implementation
This project details the design and implementation of a high-performance 1×3 Packet Router using Verilog HDL. Developed as a core exploration into digital system design and VLSI architectures, this router serves as a fundamental building block for Network-on-Chip (NoC) communication systems. The primary function of the device is to efficiently route incoming data packets to one of three designated output ports based on the destination address embedded within the packet header.

Architecture and Modular Design
The design utilizes a modular hierarchy to ensure scalability and ease of debugging. The system is partitioned into several critical components:

Input Synchronizer: Manages the timing and synchronization of incoming data to ensure the router operates correctly within the system clock domain.

FSM Controller: The "brain" of the router, implemented as a robust Finite State Machine. It manages the state transitions—including IDLE, LOAD_HEADER, LOAD_DATA, and CHECK_PARITY—to orchestrate the data movement throughout the device.

FIFO Buffering: To handle data rate mismatches and prevent packet loss, each output port is equipped with a dedicated First-In-First-Out (FIFO) buffer. These buffers provide temporary storage, ensuring smooth data flow even when the output bus is congested.

Register Block: Internal registers store the packet payload and configuration data during the routing process.

Error Detection and Reliability
A key highlight of this implementation is the integration of an Internal Parity Generator. This module calculates and verifies parity bits for each packet to ensure data integrity. If a mismatch is detected, the system triggers an error flag, demonstrating a focus on hardware reliability and fault-tolerant design.

Verification and Simulation
The project was rigorously verified using a comprehensive Testbench. The simulation environment tested various scenarios, including:

Standard Routing: Directing packets to Ports 0, 1, and 2 sequentially.

Back-pressure Handling: Observing FSM behavior when FIFO buffers reach full capacity.

Error Injection: Validating the parity checker by introducing corrupted data bits.

This project serves as a practical application of RTL coding, hardware resource optimization, and synchronous digital logic design.
