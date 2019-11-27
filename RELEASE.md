# Release Process

1. Change `PROGDATE` and `PROGVER` in [main script](./man-to-md.pl)
2. Change date and version in `.TH` line in the [man page](doc/man-to-md.1)
3. <code>make [README.md](./README.md)</code>
4. Commit all of these changes, message: <code>release v<i>x.y.z</i></code>
5. Tag that commit, tag name: <code>v<i>x.y.z</i></code>

