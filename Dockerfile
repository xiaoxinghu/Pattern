FROM swiftdocker/swift
ADD . /Pattern
WORKDIR /Pattern
RUN swift test