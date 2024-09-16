# autoring
A ring buffer library in zig. This is a port of the go package [eapache/queue](https://github.com/eapache/queue/)

Autoring isn't a true ring buffer since it doesn't have a fixed size. It follows a hybrid approach, upon hitting capacity:
- the tail pointer wraps around
- but the queue also resizes to allocate a bigger space
