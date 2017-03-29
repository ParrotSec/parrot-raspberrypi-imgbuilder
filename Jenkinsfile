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
    stage('artifacts') {
      steps {
        archiveArtifacts(artifacts: '*.tar.gz *.tar.bz2 *.contents *.files *.packages *.build-log.txt *.tar.xz *.md5sum* *.sha1sum*', onlyIfSuccessful: true)
      }
    }
  }
}