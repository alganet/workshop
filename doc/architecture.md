# Unsorted Architecture Bits

... soon to be properly organized

## The workshop executable

TL;DR Module (down)loader

The workshop executable is the starting point of everything. It has
almost no dependencies except for any POSIX Shell, core utilities like
sed and grep and curl/wget to optionally fetch new modules.

It has multiple yet similar purposes:

  - It loads required modules and nested dependencies.

        #!/usr/bin/env workshop
        require 'somemodule'

  - It downloads dependencies from a single server which can be changed.

        workshop_server="http://localhost/"

  - It acts library which exposes a single workshop function.

        . ./workshop.sh
        workshop "${0}" somemodule

  - It acts as an executable which starts the workshop function.

        ./workshop.sh somemodule

  - It works as an interpreter which runs workshop modules.

        ./workshop.sh somemodule.sh


It can download dependencies on demand and run them on the same process.





