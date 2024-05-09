## Overview

Elastic IP addresses are a costly resource to maintain, if they are unattached you will be accruing costs without any benefit; therefore unattached Elastic IP addresses should be released if not required.

This control aims to allow you to detect unattached Elastic IP addresses and then send a notification, attempt a corrective action or ignore it.

## Getting Started

This control will work out-of-the-box with some sensible defaults (configurable via [variables](https://flowpipe.io/docs/build/mod-variables)).

You should be able to simply run the following commands to begin identifying resources which need attention.

First, start up Flowpipe server from the mod directory:
```sh
flowpipe server
```

Then in another terminal session/window run:
```sh
flowpipe pipeline run detect_and_correct_vpc_eips_unattached --host local
```

You should receive notification messages for the detections in your configured [notifier](https://flowpipe.io/docs/reference/config-files/notifier).

### 