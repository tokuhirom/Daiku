requires 'perl', '5.008001';

requires 'Mouse', '0.92';
requires 'Mouse::Role';
requires 'Scalar::Util';
requires 'Time::HiRes', '1.9701';
requires 'IPC::System::Simple';
requires 'Tie::IxHash';
requires 'autodie';
requires 'Getopt::Long', '2.39';
requires 'Pod::Usage';

on configure => sub {
    requires 'Module::Build::Tiny', '0.035';
};

on test => sub {
    requires 'Capture::Tiny';
    requires 'Fatal';
    requires 'File::Temp';
    requires 'Test::More', '0.98';
    requires 'parent';
};
