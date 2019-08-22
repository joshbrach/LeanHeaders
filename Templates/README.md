#  Templates

These Templates may be installed by copying them to your User Templates directory (currently `~/Library/Developer/Xcode/Templates/File\ Templates/` in Xcode 10 ) or by creating a symlink from there to this directory.  Xcode will pick up on the new File Templates the next time you create a new file (⌘N) — you do not have to relaunch Xcode!  User File Templates are at the bottom of the list of available Templates in the New FIle wizard.

```sh
# From the root directory of this repository:
mkdir -p ~/Library/Developer/Xcode/Templates/File\ Templates && ln -s ./Templates ~/Library/Developer/Xcode/Templates/File\ Templates/LeanHeaders
```

Please use the Parser Template when making new Parsers.
