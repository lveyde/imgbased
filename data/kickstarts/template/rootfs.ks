
%include ../partial/header.ks

clearpart --all --initlabel
bootloader --append="console=ttyS0" --timeout=1

part / --size=2048 --fstype=ext4 --label=Image-0.0 --fsoptions=discard

%include ../partial/repositories.ks
%include ../partial/packages.ks
%include ../partial/post.ks
