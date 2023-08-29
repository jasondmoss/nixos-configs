{
  qtModule, qtbase, qtdeclarative, protobuf, grpc
}:
qtModule rec {
  pname = "qtgrpc";
  qtInputs = [ qtbase qtdeclarative ];
  buildInputs = [ protobuf grpc ];

  patches = [
    ./patches/qtgrpc-clientdeclarationprinter-remove-protobuf-logging.patch
    ./patches/qtgrpc-generatorbase-remove-protobuf-logging.patch
    ./patches/qtgrpc-qgrpcgenerator-remove-protobuf-logging.patch
  ];
#    ./patches/qtgrpc-qprotobufgenerator-remove-protobuf-logging.patch
}
