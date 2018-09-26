# Phoenix Support

If your application has extra steps required, you may make use of the hooks
system to add additional functionality. A common case is for building assets for Phoenix
applications.

### Using the bootleg_phoenix package

To run these steps automatically you may include the additional package
`bootleg_phoenix` in your `deps` list. This package provides the build hook commands required to build most Phoenix releases.

See also: [labzero/bootleg_phoenix](https://github.com/labzero/bootleg_phoenix)