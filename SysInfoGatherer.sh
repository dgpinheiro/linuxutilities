#!/bin/bash
#
#              INGLÊS/ENGLISH
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#  http://www.gnu.org/copyleft/gpl.html
#
#
#             PORTUGUÊS/PORTUGUESE
#  Este programa é distribuído na expectativa de ser útil aos seus
#  usuários, porém NÃO TEM NENHUMA GARANTIA, EXPLÍCITAS OU IMPLÍCITAS,
#  COMERCIAIS OU DE ATENDIMENTO A UMA DETERMINADA FINALIDADE.  Consulte
#  a Licença Pública Geral GNU para maiores detalhes.
#  http://www.gnu.org/copyleft/gpl.html
#
#  Copyright (C) 2012  Universidade de São Paulo
#
#  Universidade de São Paulo
#  Laboratório de Biologia do Desenvolvimento de Abelhas
#  Núcleo de Bioinformática (LBDA-BioInfo)
#
#  Daniel Guariz Pinheiro
#  dgpinheiro@gmail.com
#  http://zulu.fmrp.usp.br/bioinfo 
#

DATE=`date +"%m-%d-%y"`

user=""
read -p "Enter User: " user
if [ ${user} ]; then

	if [ "${USER}" == ${user} ]; then
		echo "Sorry. The User must be different from the current user."
		exit
	fi
else
	echo "Sorry. Enter an User name."
	exit
fi

mypasswd=""
read -s -p "Enter Password: " mypasswd
echo ""

typ="workstation"
iplist=(192.168.0.1 192.168.0.2)
for IP in "${iplist[@]}"; do
	echo "Processing ${typ} ${IP} ..."
	execRemoteSSH.pl -i ${IP} -c parted="sudo parted -l -s | cat" -c free="sudo free -b | cat" -c df="sudo df -vhT | cat" -c memory="sudo dmidecode --type memory | cat" -c arch="sudo uname --machine | cat" -c os="sudo cat /proc/version | cat" -c cache="sudo dmidecode --type cache | cat" -c processor="sudo dmidecode --type processor | cat" -c chassis="sudo dmidecode --type chassis | cat" -c IP="sudo hostname --ip-address | cat" -c hostname="sudo hostname -A | cat" -c system="sudo dmidecode --type system | cat" -p info_${DATE}_ -u ${user} -e <<< ${mypasswd} 

	extractPubInfo.pl -m info_${DATE}_${IP}_memory_stdout.txt -a info_${DATE}_${IP}_arch_stdout.txt -o info_${DATE}_${IP}_os_stdout.txt -e info_${DATE}_${IP}_cache_stdout.txt -p info_${DATE}_${IP}_processor_stdout.txt -c info_${DATE}_${IP}_chassis_stdout.txt -i info_${DATE}_${IP}_IP_stdout.txt -t info_${DATE}_${IP}_hostname_stdout.txt -s info_${DATE}_${IP}_system_stdout.txt -d info_${DATE}_${IP}_df_stdout.txt -f info_${DATE}_${IP}_free_stdout.txt -r info_${DATE}_${IP}_parted_stdout.txt > Report_${typ}_${DATE}_${IP}.txt
done	

typ="server"
serveriplist=(192.168.10.1 192.168.10.2)
for IP in "${serveriplist[@]}"; do
	echo "Processing ${typ} ${IP} ..."
	execRemoteSSH.pl -i ${IP} -c parted="sudo parted -l -s | cat" -c free="sudo free -b | cat" -c df="sudo df -vhT | cat" -c memory="sudo dmidecode --type memory | cat" -c arch="sudo uname --machine | cat" -c os="sudo cat /proc/version | cat" -c cache="sudo dmidecode --type cache | cat" -c processor="sudo dmidecode --type processor | cat" -c chassis="sudo dmidecode --type chassis | cat" -c IP="sudo hostname --ip-address | cat" -c hostname="sudo hostname -A | cat" -c system="sudo dmidecode --type system | cat" -p info_${DATE}_ -u ${user} -e <<< ${mypasswd} 

	extractPubInfo.pl -m info_${DATE}_${IP}_memory_stdout.txt -a info_${DATE}_${IP}_arch_stdout.txt -o info_${DATE}_${IP}_os_stdout.txt -e info_${DATE}_${IP}_cache_stdout.txt -p info_${DATE}_${IP}_processor_stdout.txt -c info_${DATE}_${IP}_chassis_stdout.txt -i info_${DATE}_${IP}_IP_stdout.txt -t info_${DATE}_${IP}_hostname_stdout.txt -s info_${DATE}_${IP}_system_stdout.txt -d info_${DATE}_${IP}_df_stdout.txt -f info_${DATE}_${IP}_free_stdout.txt -r info_${DATE}_${IP}_parted_stdout.txt > Report_${typ}_${DATE}_${IP}.txt
done

typ="cluster"
clusteriplist=(192.168.100.1)
for IP in "${clusteriplist[@]}"; do
	echo "Processing ${typ} ${IP} ..."
	execRemoteSSH.pl -i ${IP} -c parted="sudo /sbin/parted -l -s | cat" -c free="sudo free -b | cat" -c df="sudo df -vhT | cat" -c memory="sudo /usr/sbin/dmidecode --type memory | cat" -c arch="sudo uname --machine | cat" -c os="sudo cat /proc/version | cat" -c cache="sudo /usr/sbin/dmidecode --type cache | cat" -c processor="sudo /usr/sbin/dmidecode --type processor | cat" -c chassis="sudo /usr/sbin/dmidecode --type chassis | cat" -c IP="sudo hostname --ip-address | cat" -c hostname="sudo hostname | cat" -c system="sudo /usr/sbin/dmidecode --type system | cat" -c ganglia="ganglia --format=MDS --select=All | cat " -p info_${DATE}_ -u ${user} -e -n Last <<< ${mypasswd} 

	extractPubInfo.pl -m info_${DATE}_${IP}_memory_stdout.txt -a info_${DATE}_${IP}_arch_stdout.txt -o info_${DATE}_${IP}_os_stdout.txt -e info_${DATE}_${IP}_cache_stdout.txt -p info_${DATE}_${IP}_processor_stdout.txt -c info_${DATE}_${IP}_chassis_stdout.txt -i info_${DATE}_${IP}_IP_stdout.txt -t info_${DATE}_${IP}_hostname_stdout.txt -s info_${DATE}_${IP}_system_stdout.txt -d info_${DATE}_${IP}_df_stdout.txt -f info_${DATE}_${IP}_free_stdout.txt -r info_${DATE}_${IP}_parted_stdout.txt -g info_${DATE}_${IP}_ganglia_stdout.txt > Report_${typ}_${DATE}_${IP}.txt
done
