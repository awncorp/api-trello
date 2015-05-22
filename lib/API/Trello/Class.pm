package API::Trello::Class;

use Extorter;

# VERSION

sub import {
    my $class  = shift;
    my $target = caller;

    $class->extort::into($target, '*Data::Object::Class');
    $class->extort::into($target, '*API::Trello::Signature');
    $class->extort::into($target, '*API::Trello::Type');

    return;
}

1;
