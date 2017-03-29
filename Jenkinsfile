pipeline {
  agent any
  stages {
    stage('setup') {
      steps {
        sh 'sudo apt-get install -y live-build qemu-user-static tar gzip xz-utils gdisk unzip wget kpartx lvm2 dosfstools coreutils parted xfsprogs'
      }
    }
    stage('configure') {
      steps {
        sh '''make clean
./configure'''
      }
    }
    stage('build') {
      steps {
        sh 'make -j8'
      }
    }
    stage('archive artifacts') {
      steps {
        archiveArtifacts(artifacts: 'parrotsec-*', caseSensitive: true)
      }
    }
  }
}