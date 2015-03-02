#!/usr/bin/perl
# status_code_extractor_yoha_complete_10h_15h.pl is a script 
# that decodes the machine check errors.
# 
# Usage 		: ./filename input_filename output_directory
# 
# Inputfile 	: filtered machine check data.
# 				Each machine check consists of 3 lines
# 				where each line contains:
# 				bank # / error address / processor id etc.
# 
# Outputfile	: a file (fully_decoded.txt) that contains 
# 				the decoded information from the input
# 				please refer to the table header in the file for
# 				detailed information
# Output		: if there are any processors that does not fall into
# 				family10h or 15h they are printed as an output
# 
# further improvements to be made:
# 	re-structure the script for more flexibilities i.e, like what Fabio has done
  
use strict; 
use warnings;
use English;
use File::Basename;
use bigint;

#Keywhan
my $input_file = $ARGV[0];
my $output_dir = $ARGV[1];
my $out_file = $output_dir."/".$input_file."_decoded";

print "Decoding Machine Check data...hold on";

use constant {
                TT_I    => 0b00,
                TT_D    => 0b01,
                TT_G    => 0b10,
                TT_RSVD => 0b11,
             };
              
              
use constant {
                LL_RSVD => 0b00,
                LL_L1   => 0b01,
                LL_L2   => 0b10,
                LL_LG   => 0b11,
             };
              
              
use constant {
                RRRR_GEN        => 0b0000,
                RRRR_RD         => 0b0001,
                RRRR_WR         => 0b0010,
                RRRR_DRD        => 0b0011,
                RRRR_DWR        => 0b0100,
                RRRR_IRD        => 0b0101,
                RRRR_PREFETCH   => 0b0110,
                RRRR_EVICT      => 0b0111,
                RRRR_PROBE      => 0b1000,
                RRRR_SNOOP      => 0b1000,
             };
              
              
use constant {
                PP_SRC => 0b00,
                PP_RES => 0b01,
                PP_OBS => 0b10,
                PP_GEN => 0b11,
             };
              
              
use constant {
                II_MEM  => 0b00,
                II_RES  => 0b01,
                II_IO   => 0b10,
                II_GEN  => 0b11,
             };
             
use constant {
                T_0  => 0,
                T_1  => 1,
             };

sub decodeErrorCode{
	my @list = @_;
	my $errorCode = $list[0];
	my $bin_pp, my $bin_t, my $bin_rrrr, my $bin_ii, my $bin_ll, my $bin_tt, my $type;
	if(($errorCode & 0xFFE0) == 0){
		$bin_tt		= ($errorCode & 0x3 << 2) >> 2;
		$bin_ll		= ($errorCode & 0x3);
		$bin_rrrr	= -1;
		$bin_pp		= -1;
		$bin_t		= -1;
		$bin_ii		= -1;
		$type = "tlb";
	}
	elsif(($errorCode & 0xFE00) == 0){
		$bin_tt		= ($errorCode & 0x3 << 2) >> 2;
		$bin_ll		= ($errorCode & 0x3);
		$bin_rrrr	= ($errorCode & 0xF << 4) >> 4;
		$bin_pp		= -1;
		$bin_t		= -1;
		$bin_ii		= -1;
		$type = "mem";
	}
	elsif(($errorCode & 0xF800) > 0){
		$bin_tt		= -1;
		$bin_ll		= ($errorCode & 0x3);
		$bin_rrrr	= ($errorCode & 0xF << 4) >> 4;
		$bin_pp		= ($errorCode & 0x3 << 9) >> 9;
		$bin_t		= ($errorCode & 0x1 << 8) >> 8;
		$bin_ii		= ($errorCode & 0x3 << 2) >> 2;
		$type = "bus";
	}
	else{
		$bin_tt		= -1;
		$bin_ll		= -1;
		$bin_rrrr	= -1;
		$bin_pp		= -1;
		$bin_t		= -1;
		$bin_ii		= -1;
		$type = "N/A";
	}
	# print "$type, $bin_tt, $bin_ll, $bin_rrrr, $bin_pp, $bin_t, $bin_ii\n";
	return ($type, $bin_tt, $bin_ll, $bin_rrrr, $bin_pp, $bin_t, $bin_ii);
}


sub decode_10
{
  my @list = @_;
  my $bank = int($list[0]);
  my $status = hex("0x".$list[1]);
  my $addr = $list[2];
  my $decoding = "";
  my $val 	= "N/A";
  my $ov 	= "N/A";
  my $uc	= "N/A"; 
  my $en	= "N/A";
  my $miscv	= "N/A";
  my $addrV	= "N/A";
  my $pcc 	= "N/A";
  my $errCoreVal = "N/A"; 
  my $cecc	= "N/A";
  my $uecc	= "N/A";
  my $def 	= "N/A";
  my $poison= "N/A";
  my $scrub = "N/A";
  my $link	= "N/A";
  my $cache_error = "N/A"; 
  my $pr_parity	= "N/A";
  my $syndrome	= "N/A";
  my $core	= "N/A";
  my $errorcode	= "N/A";
  my $ext_errorcode	= "N/A";
  my $addr_desc = "";
  my $mcaStatSubCache = "N/A";
  my $sublink = "N/A";
  my $ldtlink = "N/A";
  
    $val = 		($status & 1 << 63) ? 1 : 0;
  $ov = 		($status & 1 << 62) ? 1 : 0;
  $uc =			($status & 1 << 61) ? 1 : 0;
  $en = 		($status & 1 << 60) ? 1 : 0;
  $miscv =		($status & 1 << 59) ? 1 : 0;
  $addrV =		($status & 1 << 58) ? 1 : 0;
  $pcc =		($status & 1 << 57) ? 1 : 0;
  $cecc = 		($status & 1 << 46) ? 1 : 0;
  $uecc =		($status & 1 << 45) ? 1 : 0;
  $ext_errorcode =	($status & 0xf << 16) >> 16;
  $errorcode =		($status & 0xffff);

  if ($bank == 0){
	  #DC
	  $syndrome =	($status & 0xff << 47) >> 47 + (($status & 0xff << 24) >> 16);
	  $scrub =		($status & 1 << 40) ? 1 : 0;
  }elsif($bank == 2){
	  #BU
	  $scrub =		($status & 1 << 40) ? 1 : 0;
  
  }elsif($bank == 4){
	  #NB
	  $errCoreVal =			($status & 1 << 56) ? 1 : 0;
	  $syndrome =			($status & 0xff << 47) >> 47 + (($status & 0xff << 24) >> 16);
	  $mcaStatSubCache =	($status & 0x3 << 42) >> 42;
	  $sublink =			($status & 1 << 41) ? 1 : 0;
	  $scrub =				($status & 1 << 40) ? 1 : 0;
	  $ldtlink =			($status & 0xf << 36) >> 36;
	  $core =				($status & 0xf << 32) >> 32;
	  $ext_errorcode = 		($status & 0x1f << 16) >> 16; # Bank4 exceptionaly has additional bit
  }elsif(($bank != 1) && ($bank != 3) && ($bank != 5)){
	  print "ERROR: unknown bank - $bank\n";
	  return 1;
  }

  my $errorType = "N/A";
  my ($type, $bin_tt, $bin_ll, $bin_rrrr, $bin_pp, $bin_t, $bin_ii, $bin_uu) = decodeErrorCode($errorcode);
  # print "$type\n";
  
  if($bank == 0){
  	# Ref: AMD 10h BKDG Table 107
  	# Please note that singlebit/multibit error was not considered, this inforation can be gathered by decoding the syndrome which is not implemented in this script
	  if(($ext_errorcode == 0x0) && ($type eq "mem") && ($bin_rrrr == 3) && ($bin_tt == 1) && ($bin_ll == 2) && ($addrV == 1)  && ($scrub == 0)){
		  $errorType = "L2 Cache Line Fill";
	  }elsif(($ext_errorcode == 0x0) && ($type eq "mem") && ($bin_rrrr == 3) && ($bin_tt == 1) && ($bin_ll == 1) && ($scrub == 0)){
		  $errorType = "Data Load";
	  }elsif(($ext_errorcode == 0x0) && ($type eq "mem") && ($bin_rrrr == 4) && ($bin_tt == 1) && ($bin_ll == 1) && ($scrub == 0)){
		  $errorType = "Data Store";
	  }elsif(($ext_errorcode == 0x0) && ($type eq "mem") && ($bin_rrrr == 7) && ($bin_tt == 1) && ($bin_ll == 1) && ($scrub == 0)){
		  $errorType = "Data Victim";
	  }elsif(($ext_errorcode == 0x0) && ($type eq "mem") && ($bin_rrrr == 8) && ($bin_tt == 1) && ($bin_ll == 1) && ($scrub == 0)){
		  $errorType = "Data Snoop";
	  }elsif(($ext_errorcode == 0x0) && ($type eq "mem") && ($bin_rrrr == 0) && ($bin_tt == 1) && ($bin_ll == 1) && ($addrV == 1) && ($pcc == 0) && ($scrub == 1)){
		  $errorType = "Data Scrub";
	  }elsif(($ext_errorcode == 0x0) && ($type eq "mem") && ($bin_rrrr == 8) && ($bin_tt == 1) && ($bin_ll == 1) && ($uc == 1) && ($pcc == 1) && ($cecc == 0) && ($uecc == 0) && ($scrub == 0)){
		  $errorType = "Tag Snoop";
		  $syndrome = "N/A";
	  }elsif(($ext_errorcode == 0x0) && ($type eq "mem") && ($bin_rrrr == 7) && ($bin_tt == 1) && ($bin_ll == 1) && ($uc == 1) && ($pcc == 1) && ($cecc == 0) && ($uecc == 0) && ($scrub == 0)){
		  $errorType = "Tag Victim";
		  $syndrome = "N/A";
	  }elsif(($ext_errorcode == 0x0) && ($type eq "mem") && ($bin_rrrr == 3) && ($bin_tt == 1) && ($bin_ll == 1) && ($uc == 1) && ($addrV == 1) && ($pcc == 1) && ($cecc == 0) && ($uecc == 0) && ($scrub == 0)){
		  $errorType = "Tag Load";
		  $syndrome = "N/A";
	  }elsif(($ext_errorcode == 0x0) && ($type eq "mem") && ($bin_rrrr == 4) && ($bin_tt == 1) && ($bin_ll == 1) && ($uc == 1) && ($addrV == 1) && ($pcc == 1) && ($cecc == 0) && ($uecc == 0) && ($scrub == 0)){
		  $errorType = "Tag Store";
		  $syndrome = "N/A";
	  }elsif(($ext_errorcode == 0x0) && ($type eq "tlb") && ($bin_tt == 1) && ($bin_ll == 1) && ($uc == 1) && ($addrV == 1) && ($pcc == 1) && ($cecc == 0) && ($uecc == 0) && ($scrub == 0)){
		  $errorType = "L1 TLB";
		  $syndrome = "N/A";
	  }elsif(($ext_errorcode == 0x1) && ($type eq "tlb") && ($bin_tt == 1) && ($bin_ll == 1) && ($uc == 1) && ($addrV == 1) && ($pcc == 1) && ($cecc == 0) && ($uecc == 0) && ($scrub == 0)){
		  $errorType = "L1 TLB Multimatch";
		  $syndrome = "N/A";
	  }elsif(($ext_errorcode == 0x0) && ($type eq "tlb") && ($bin_tt == 1) && ($bin_ll == 2) && ($uc == 1) && ($addrV == 1) && ($pcc == 1) && ($cecc == 0) && ($uecc == 0) && ($scrub == 0)){
		  $errorType = "L2 TLB";
		  $syndrome = "N/A";
	  }elsif(($ext_errorcode == 0x1) && ($type eq "tlb") && ($bin_tt == 1) && ($bin_ll == 2) && ($uc == 1) && ($addrV == 1) && ($pcc == 1) && ($cecc == 0) && ($uecc == 0) && ($scrub == 0)){
		  $errorType = "L2 TLB Multimatch";
		  $syndrome = "N/A";
	  }
  }
  elsif($bank == 1){# print "bank1 : $status\n"
  	# Ref AMD 10h BKDG Table 110
	  if(($ext_errorcode == 0x0) && ($type eq "bus") && ($bin_pp == 0) && ($bin_t == 0) && ($bin_rrrr == 5) && ($bin_ii == 0) && ($bin_ll == 3) && ($uc == 1) && ($addrV == 0) && ($pcc == 0) && ($cecc == 0) && ($uecc == 0) && ($scrub == 0)){
		  $errorType = "System Data Read Error";
	  }elsif(($ext_errorcode == 0x0) && ($type eq "mem") && ($bin_rrrr == 5) && ($bin_tt == 0) && ($bin_ll == 2) && ($uc == 0) && ($addrV == 1) && ($pcc == 0) && ($cecc == 0) && ($uecc == 1) && ($scrub == 0)){
		  $errorType = "L2 Cache Line Fill";
	  }elsif(($ext_errorcode == 0x0) && ($type eq "mem") && ($bin_rrrr == 5) && ($bin_tt == 0) && ($bin_ll == 1) && ($uc == 0) && ($addrV == 1) && ($pcc == 0) && ($cecc == 0) && ($uecc == 0) && ($scrub == 0)){
		  $errorType = "IC Data Load(Parity)";
	  }elsif(($ext_errorcode == 0x0) && ($type eq "mem") && ($bin_rrrr == 8) && ($bin_tt == 0) && ($bin_ll == 1) && ($uc == 1) && ($addrV == 1) && ($pcc == 1) && ($cecc == 0) && ($uecc == 0) && ($scrub == 0)){
		  $errorType = "Tag Snoop";
	  }elsif(($ext_errorcode == 0x0) && ($type eq "mem") && ($bin_rrrr == 7) && ($bin_tt == 0) && ($bin_ll == 1) && ($uc == 0) && ($addrV == 0) && ($pcc == 0) && ($cecc == 0) && ($uecc == 0) && ($scrub == 0)){
		  $errorType = "Copyback Parity";
	  }elsif(($ext_errorcode == 0x0) && ($type eq "tlb") && ($bin_tt == 0) && ($bin_ll == 1) && ($uc == 0) && ($addrV == 1) && ($pcc == 0) && ($cecc == 0) && ($uecc == 0) && ($scrub == 0)){
		  $errorType = "L1 TLB";
	  }elsif(($ext_errorcode == 0x1) && ($type eq "tlb") && ($bin_tt == 0) && ($bin_ll == 1) && ($uc == 0) && ($addrV == 1) && ($pcc == 0) && ($cecc == 0) && ($uecc == 0) && ($scrub == 0)){
		  $errorType = "L1 TLB Multimatch";
	  }elsif(($ext_errorcode == 0x0) && ($type eq "tlb") && ($bin_tt == 0) && ($bin_ll == 2) && ($uc == 0) && ($addrV == 1) && ($pcc == 0) && ($cecc == 0) && ($uecc == 0) && ($scrub == 0)){
		  $errorType = "L2 TLB";
	  }elsif(($ext_errorcode == 0x1) && ($type eq "tlb") && ($bin_tt == 0) && ($bin_ll == 2) && ($uc == 0) && ($addrV == 1) && ($pcc == 0) && ($cecc == 0) && ($uecc == 0) && ($scrub == 0)){
		  $errorType = "L2 TLB Multimatch";
	  }
  }
  elsif($bank == 2){
  	# Ref AMD 10h BKDG Table 113
	  if(($ext_errorcode == 0x0) && ($type eq "bus") && ($bin_pp == 0) && ($bin_t == 0) && ($bin_rrrr == 1) && (($bin_ii == 0) || ($bin_ii == 2)) && ($bin_ll == 3) && ($uc == 1) && ($addrV == 1) && ($pcc == 0) && ($cecc == 0) && ($uecc == 0) && ($scrub == 0)){
		  $errorType = "SystemDataReadError_TLB";
	  }elsif(($ext_errorcode == 0x0) && ($type eq "bus") && ($bin_pp == 0) && ($bin_t == 0) && ($bin_rrrr == 6) && (($bin_ii == 0) || ($bin_ii == 2)) && ($bin_ll == 3) && ($uc == 1) && ($addrV == 0) && ($pcc == 0) && ($cecc == 0) && ($uecc == 0) && ($scrub == 0)){
		  $errorType = "SystemDataReadError_HWPrefetch";
	  }elsif(($ext_errorcode == 0x0) && ($type eq "mem") && ($bin_rrrr == 1) && ($bin_tt == 2) && ($bin_ll == 2) && ($addrV == 1) && ($pcc == 0) && ($scrub == 0)){
		  $errorType = "L2CacheData_TLB";
	  }elsif(($ext_errorcode == 0x0) && ($type eq "mem") && ($bin_rrrr == 0) && ($bin_tt == 2) && ($bin_ll == 2) && ($addrV == 1) && ($pcc == 0) && ($scrub == 1)){
		  $errorType = "L2CacheData_Scrub";
	  }elsif(($ext_errorcode == 0x11) && ($type eq "mem") && (($bin_rrrr == 7) || ($bin_rrrr == 8)) && ($bin_tt == 2) && ($bin_ll == 3) && ($pcc == $uc) && ($cecc == 0) && ($uecc == 0) && ($scrub == 0)){
		  $errorType = "DataBuffer_Victim";
	  }elsif(($ext_errorcode == 0x1) && ($type eq "mem") && ($bin_rrrr == 2) && ($bin_tt == 2) && ($bin_ll == 3) && ($pcc == $uc) && ($cecc == 0) && ($uecc == 0) && ($scrub == 0)){
		  $errorType = "DataBuffer_Write";
	  }elsif(($ext_errorcode == 0x0) && ($type eq "mem") && ($bin_rrrr == 8) && ($bin_tt == 2) && ($bin_ll == 2) && ($addrV == 1) && ($pcc == $uc) && ($scrub == 0)){
		  $errorType = "DataCopyBack_Snoop";
	  }elsif(($ext_errorcode == 0x0) && ($type eq "mem") && ($bin_rrrr == 7) && ($bin_tt == 2) && ($bin_ll == 2) && ($addrV == 1) && ($pcc == $uc) && ($scrub == 0)){
		  $errorType = "DataCopyBack_Evict";
	  }elsif(($ext_errorcode == 0x10) && ($type eq "mem") && ($bin_rrrr == 5) && ($bin_tt == 0) && ($bin_ll == 2) && ($addrV == 1) && ($pcc == $uc) && ($scrub == 0)){
		  $errorType = "Tag_InstrFetch";
	  }elsif(($ext_errorcode == 0x10) && ($type eq "mem") && ($bin_rrrr == 3) && ($bin_tt == 1) && ($bin_ll == 2) && ($addrV == 1) && ($pcc == $uc) && ($scrub == 0)){
		  $errorType = "Tag_DataFetch";
	  }elsif(($ext_errorcode == 0x10) && ($type eq "mem") && ($bin_rrrr == 1) && ($bin_tt == 2) && ($bin_ll == 2) && ($addrV == 1) && ($pcc == $uc) && ($scrub == 0)){
		  $errorType = "Tag_TLB";
	  }elsif(($ext_errorcode == 0x10) && ($type eq "mem") && ($bin_rrrr == 8) && ($bin_tt == 2) && ($bin_ll == 2) && ($addrV == 1) && ($pcc == $uc) && ($scrub == 0)){
		  $errorType = "Tag_Snoop";
	  }elsif(($ext_errorcode == 0x10) && ($type eq "mem") && ($bin_rrrr == 7) && ($bin_tt == 2) && ($bin_ll == 2) && ($addrV == 1) && ($pcc == $uc) && ($scrub == 0)){
		  $errorType = "Tag_Evict";
	  }elsif(($ext_errorcode == 0x10) && ($type eq "mem") && ($bin_rrrr == 0) && ($bin_tt == 2) && ($bin_ll == 2) && ($addrV == 1) && ($pcc == 0) && ($scrub == 1)){
		  $errorType = "Tag_Scrub";
	  }elsif(($ext_errorcode == 0x0) && ($type eq "tlb") && ($bin_tt == 0) && ($bin_ll == 1) && ($cecc == 0) && ($uecc == 0) && ($scrub == 0)){
		  $errorType = "PDCandGTLBParityError_InstrFetch";
	  }elsif(($ext_errorcode == 0x0) && ($type eq "tlb") && ($bin_tt == 1) && ($bin_ll == 1) && ($cecc == 0) && ($uecc == 0) && ($scrub == 0)){
		  $errorType = "PDCandGTLBParityError_DataFetch";
	  }
  }
  elsif($bank == 3){
  	# Ref Table 115
	  if(($ext_errorcode == 0x0) && ($type eq "bus") && ($bin_pp == 0) && ($bin_t == 0) && ($bin_rrrr == 4) && ($bin_ii == 0) && ($bin_ll == 3) && ($uc == 1) && ($cecc == 0) && ($uecc == 0) && ($scrub == 0)){
		  $errorType = "Read Data on Store";
	  }elsif(($ext_errorcode == 0x0) && ($type eq "bus") && ($bin_pp == 0) && ($bin_t == 0) && ($bin_rrrr == 3) && (($bin_ii == 0) || ($bin_ii == 2)) && ($bin_ll == 3) && ($uc == 1) && ($cecc == 0) && ($uecc == 0) && ($scrub == 0)){
		  $errorType = "Read Data on Load";
	  }
  }
  elsif($bank == 4){
  	#Ref Tabl2 93
	  if(($ext_errorcode == 0x1) && ($type eq "bus") && ($bin_pp == 2) && ($bin_t == 0) && ($bin_rrrr == 0) && ($bin_ii == 3) && ($bin_ll == 3) && ($uc == 1) && ($addrV == 0) && ($pcc == 1) && ($cecc == 0) && ($uecc == 0) && ($scrub == 0)){
		  $errorType = "CRC Error";
		  $syndrome = "N/A";
		  $core = "N/A";
	  }elsif(($ext_errorcode == 0x2) && ($type eq "bus") && ($bin_pp == 2) && ($bin_t == 0) && ($bin_rrrr == 0) && ($bin_ii == 3) && ($bin_ll == 3) && ($uc == 1) && ($addrV == 0) && ($pcc == 1) && ($cecc == 0) && ($uecc == 0) && ($scrub == 0)){
		  $errorType = "Sync Error";
		  $syndrome = "N/A";
		  $core = "N/A";
	  }elsif(($ext_errorcode == 0x3) && ($type eq "bus") && (($bin_pp == 0) || ($bin_pp == 2)) && ($bin_t == 0) && (($bin_rrrr == 1) || ($bin_rrrr == 2)) && (($bin_ii == 0) || ($bin_ii == 2)) && ($bin_ll == 3) && ($uc == 1) && ($addrV == 1) && ($cecc == 0) && ($uecc == 0) && ($scrub == 0)){
		  $errorType = "Mst Abort";
		  $syndrome = "N/A";
	  }elsif(($ext_errorcode == 0x4) && ($type eq "bus") && (($bin_pp == 0) || ($bin_pp == 2)) && ($bin_t == 0) && (($bin_rrrr == 1) || ($bin_rrrr == 2)) && (($bin_ii == 0) || ($bin_ii == 2)) && ($bin_ll == 3) && ($uc == 1) && ($addrV == 1) && ($cecc == 0) && ($uecc == 0) && ($scrub == 0)){
		  $errorType = "Tgt Abort";
		  $syndrome = "N/A";
	  }elsif(($ext_errorcode == 0x5) && ($type eq "tlb") && ($bin_tt == 2) && ($bin_ll == 3) && ($uc == 1) && ($addrV == 1) && ($cecc == 0) && ($uecc == 0) && ($scrub == 0)){
		  $errorType = "GART Error";
		  $syndrome = "N/A";
		  $ldtlink = "N/A";
	  }elsif(($ext_errorcode == 0x6) && ($type eq "bus") && ($bin_pp == 2) && ($bin_t == 0) && ($bin_rrrr == 0) && ($bin_ii == 2) && ($bin_ll == 3) && ($uc == 1) && ($addrV == 1) && ($pcc == 0) && ($cecc == 0) && ($uecc == 0) && ($scrub == 0)){
		  $errorType = "RMW Error";
		  $syndrome = "N/A";
		  $core = "N/A";
	  }elsif(($ext_errorcode == 0x7) && ($type eq "bus") && ($bin_pp == 3) && ($bin_t == 1) && ($bin_rrrr == 0) && ($bin_ii == 3) && ($bin_ll == 3) && ($uc == 1) && ($addrV == 0) && ($pcc == 1) && ($cecc == 0) && ($uecc == 0) && ($scrub == 0)){
		  $errorType = "WDT Error";
		  $syndrome = "N/A";
		  $ldtlink = "N/A";
		  $core = "N/A";
	  }elsif(($ext_errorcode == 0x8) && ($type eq "bus") && (($bin_pp == 0) || ($bin_pp == 1)) && ($bin_t == 0) && (($bin_rrrr == 1) || ($bin_rrrr == 2)) && ($bin_ii == 0) && ($bin_ll == 3) && ($addrV == 1)){
		  $errorType = "ECC Error";
		  $ldtlink = "N/A";
		  $core = "N/A";
	  }elsif(($ext_errorcode == 0x9) && ($type eq "bus") && (($bin_pp == 0) || ($bin_pp == 2)) && ($bin_t == 0) && (($bin_rrrr == 1) || ($bin_rrrr == 2)) && (($bin_ii == 0) || ($bin_ii == 2)) && ($bin_ll == 3) && ($uc == 1) && ($addrV == 1) && ($pcc == 0) && ($cecc == 0) && ($uecc ==0 ) && ($scrub == 0)){
		  $errorType = "Dev Error";
		  $syndrome = "N/A";
		  $core = "N/A";
	  }elsif(($ext_errorcode == 0xA) && ($type eq "bus") && (($bin_pp == 0) || ($bin_pp == 2)) && ($bin_t == 0) && (($bin_rrrr == 1) || ($bin_rrrr == 2) || ($bin_rrrr == 4)) && (($bin_ii == 0) || ($bin_ii == 2)) && ($bin_ll == 3) && ($uc == 1) && ($addrV == 1) && ($cecc == 0) && ($uecc == 0) && ($scrub == 0)){
		  $errorType = "Link Data Error";
		  $syndrome = "N/A";
		  $core = "N/A";
	  }elsif(($ext_errorcode == 0xB) && ($type eq "bus") && ($bin_pp == 2) && ($bin_t == 0) && ($bin_rrrr == 0) && ($bin_ii == 3) && ($bin_ll == 3) && ($uc == 1) && ($pcc == 1) && ($cecc == 0) && ($uecc == 0) && ($scrub == 0)){
		  $errorType = "Protocol Error";
		  $syndrome = "N/A";
		  $core = "N/A";
	  }elsif(($ext_errorcode == 0xC) && ($type eq "bus") && ($bin_pp == 2) && ($bin_t == 0) && ($bin_rrrr == 0) && ($bin_ii == 3) && ($bin_ll == 3) && ($uc == 1) && ($addrV == 1) && ($pcc == 1) && ($cecc == 0) && ($uecc == 0) && ($scrub == 0)){
		  $errorType = "NB Array Error";
		  $syndrome = "N/A";
		  $ldtlink = "N/A";
		  $core = "N/A";
	  }elsif(($ext_errorcode == 0xD) && ($type eq "bus") && ($bin_pp == 2) && ($bin_t == 0) && ($bin_rrrr == 0) && ($bin_ii == 0) && ($bin_ll == 3) && ($uc == 1) && ($addrV == 0) && ($pcc == 1) && ($cecc == 0) && ($uecc == 0) && ($scrub == 0)){
		  $errorType = "DRAM Parity Error";
		  $syndrome = "N/A";
		  $ldtlink = "N/A";
		  $core = "N/A";
	  }elsif(($ext_errorcode == 0xE) && ($type eq "bus") && ($bin_pp == 2) && ($bin_t == 0) && ($bin_rrrr == 0) && ($bin_ii == 3) && ($bin_ll == 3) && ($uc == 0) && ($addrV == 0) && ($pcc == 0) && ($cecc == 0) && ($uecc == 0) && ($scrub == 0)){
		  $errorType = "Link Retry";
		  $syndrome = "N/A";
		  $core = "N/A";
	  }elsif(($ext_errorcode == 0xF) && ($type eq "tlb") && ($bin_tt == 2) && ($bin_ll == 3) && ($uc == 1) && ($addrV == 1) && ($cecc == 0) && ($uecc == 0) && ($scrub == 0)){
		  $errorType = "GART Table Walk Data Error";
		  $syndrome = "N/A";
		  $ldtlink = "N/A";
	  }elsif(($ext_errorcode == 0xF) && ($type eq "bus") && ($bin_pp == 2) && ($bin_t == 0) && ($bin_rrrr == 0) && ($bin_ii == 0) && ($bin_ll == 3) && ($uc == 1) && ($addrV == 1) && ($pcc == 0) && ($cecc == 0) && ($uecc == 0) && ($scrub == 0)){
		  $errorType = "DEV Table Walk Data Error";
		  $syndrome = "N/A";
		  $ldtlink = "N/A";
		  $core = "N/A";
	  }elsif(($ext_errorcode == 0x1F) && ($type eq "mem") && (($bin_rrrr == 0) || ($bin_rrrr == 1) || ($bin_rrrr == 7) || ($bin_rrrr = 8)) && ($bin_tt == 2) && ($bin_ll == 3) && ($uc == 0) && ($addrV == 1) && ($pcc == 0)){
		  $errorType = "Probe Filter Error";
	  }elsif(($ext_errorcode == 0x1C) && ($type eq "mem") && (($bin_rrrr == 0) || ($bin_rrrr == 1) || ($bin_rrrr == 7) || ($bin_rrrr = 8)) && ($bin_tt == 2) && ($bin_ll == 3) && ($uc == $uecc) && ($addrV == 1) && ($pcc == ($uc & !$scrub))){
		  $errorType = "L3 Cache Data Error";
	  }elsif(($ext_errorcode == 0x1D) && ($type eq "mem") && (($bin_rrrr == 0) || ($bin_rrrr == 1) || ($bin_rrrr == 7) || ($bin_rrrr = 8)) && ($bin_tt == 2) && ($bin_ll == 3) && ($uc == $uecc) && ($addrV == 1) && ($pcc == ($uc & !$scrub))){
		  $errorType = "L3 Cache Tag Error";
	  }elsif(($ext_errorcode == 0x1E) && ($type eq "mem") && (($bin_rrrr == 0) || ($bin_rrrr == 1) || ($bin_rrrr == 7) || ($bin_rrrr = 8)) && ($bin_tt == 2) && ($bin_ll == 3) && ($uc == $uecc) && ($addrV == 1) && ($pcc == 0) && ($cecc == 0)){
		  $errorType = "L3 Cache LRU Error";
		  $syndrome = "N/A";
		  $ldtlink = "N/A";
		  $core = "N/A";
	  }
  }
  elsif($bank == 5){
	  if(($type eq "bus") && ($bin_pp == 3) && ($bin_t == 1) && ($bin_rrrr == 0) && ($bin_ii == 3) && ($bin_ll == 3) && ($uc == 1) && ($addrV == 1) && ($pcc == 1) && ($cecc == 0) && ($uecc == 0) && ($scrub == 0)){
		  $errorType = "CPU Watchdog timer expire";
	  }
  }
	

		
  $cache_error = ((($cache_error !~ /\D/) && ($cache_error ne ""))) ? sprintf("%b", $cache_error) : $cache_error;
  $pr_parity = ((($pr_parity !~ /\D/) && ($pr_parity ne ""))) ? sprintf("%b", $pr_parity) : $pr_parity;
  $syndrome = ((($syndrome !~ /\D/) && ($syndrome ne ""))) ? sprintf("%b", $syndrome) : $syndrome;
  $addr = ((($addr !~ /\D/) && ($addr ne ""))) ? sprintf("%x", $addr) : $addr;
  # $core = ($core != "N/A") ? sprintf("%b", $core) : $core;
  $errorcode = ((($errorcode !~ /\D/) && ($errorcode ne ""))) ? sprintf("%b", $errorcode) : $errorcode;		
  $ext_errorcode = ((($ext_errorcode !~ /\D/) && ($ext_errorcode ne ""))) ? sprintf("%b", $ext_errorcode) : $ext_errorcode;		

  #print "$errorcode\n";
  return "$val\t$ov\t$uc\t$pcc\t$cecc\t$uecc\t$def\t$poison\t$mcaStatSubCache\t$sublink\t$ldtlink\t$scrub\t$link\t$cache_error\t$syndrome\t$core\t$errorcode\t$ext_errorcode\t$errorType\t$addr\t$addr_desc\t$type";
}


sub decode_15
{
  my @list = @_;
    
  my $bank = int($list[0]);
  my $status = hex("0x".$list[1]);
  my $addr = hex("0x".$list[2]);
  my $raw_addr = $addr;
  my $decoding = "";
  my $val, my $ov, my $uc, my $en, my $miscv, my $addrv, my $pcc, my $errCoreVal, my $cecc, my $uecc,  my $def, my $poison, my $l3_subcache = "N/A", my $sublink = "N/A", my $ldtlink = "N/A", my $scrub, my $link, my $cache_way, 
  my $syndrome, my $core, my $errorcode, my $ext_errorcode, my $addr_desc = "";
  my $error_type = "N/A";
  
  
  my ($code_type, $bin_tt, $bin_ll, $bin_rrrr, $bin_pp, $bin_t, $bin_ii);
  
  # print "$bank : $addr\n";
  
  if($bank == 0)	{# print "bank0 : $status\n"
			  $val = 		($status & 1 << 63) ? 1 : 0;
			  $ov = 		($status & 1 << 62) ? 1 : 0;
			  $uc =			($status & 1 << 61) ? 1 : 0;
			  $en = 		($status & 1 << 60) ? 1 : 0;
			  $miscv =		($status & 1 << 59) ? 1 : 0;
			  $addrv =		($status & 1 << 58) ? 1 : 0;
			  $pcc =		($status & 1 << 57) ? 1 : 0;
			  $cecc = 		"N/A";
			  $uecc = 		"N/A";
			  $def =		($status & 1 << 44) ? 1 : 0;
			  $poison =		($status & 1 << 43) ? 1 : 0;
			  $scrub =		"N/A";
			  $link =		"N/A";
			  $cache_way = 	        ($status & 0xF << 36) >> 36;
			  $syndrome = 		"N/A";
			  $core = 		"N/A";
			  $errorcode =		($status & 0xFFFF);
			  $ext_errorcode =	($status & 0x1F << 16) >> 16;
			  
			  
                          ($code_type, $bin_tt, $bin_ll, $bin_rrrr, $bin_pp, $bin_t, $bin_ii) = decodeErrorCode($errorcode);
                          
                          if($ext_errorcode == 0b00001 &&   $code_type eq "mem" &&  $bin_pp == $bin_pp &&   $bin_t == $bin_t     &&         $bin_rrrr == RRRR_DRD && 
                                          $bin_tt == TT_D &&                            $bin_ll == LL_LG &&     $uc == 1 &&     $addrv == 1 &&          $pcc == 0 &&            $def == 0 &&    $poison == 1) 
                          {
                              $error_type = "Line Fill Error" ;
                              $addr = ($addr & 0xFFFFFFFFFFB0) >> 6;
                              $addr_desc = "Physical";
                          }
                          
                          if($ext_errorcode == 0b00000 && $code_type eq "mem" && $bin_pp == $bin_pp && $bin_t == $bin_t     && $bin_rrrr == RRRR_DRD && 
                                          $bin_tt == TT_D &&                            $bin_ll == LL_L1 &&     $uc == $uc &&   $addrv == 1 &&          $pcc == 0 &&            $def == 0 &&    $poison == 0) 
                          {
                              $error_type = "Data Cache Error : Data Array";
                              $addr = ($addr & 0xFFFFFFFFFFF0) >> 4;
                              $addr_desc = "Physical";
                          }
                          
                          if($ext_errorcode == 0b00011 && $code_type eq "mem" && $bin_pp == $bin_pp && $bin_t == $bin_t     && $bin_rrrr == RRRR_DRD && 
                                          $bin_tt == TT_D &&                            $bin_ll == LL_L1 &&     $uc == $uc &&   $addrv == 1 &&          $pcc == 0 &&            $def == 0 &&    $poison == 0) 
                          {
                              $error_type = "Data Cache Error : SCB";
                              $addr = ($addr & 0xFF0) >> 4;
                              $addr_desc = "Physical";
                          }
                          
                          if($ext_errorcode == 0b00010 && $code_type eq "mem" && $bin_pp == $bin_pp && $bin_t == $bin_t     && $bin_rrrr == RRRR_DRD && 
                                          $bin_tt == TT_D &&                            $bin_ll == LL_L1 &&     $uc == $uc &&   $addrv == 1 &&          $pcc == $pcc &&         $def == 0 &&    $poison == 0) 
                          {
                              $error_type = "Data Cache Error : STQ";
                              $addr = ($addr & 0x1F) >> 0;
                              $addr_desc = "Index";
                          }
                          
                          if($ext_errorcode == 0b10000 && $code_type eq "mem" && $bin_pp == $bin_pp && $bin_t == $bin_t     && ($bin_rrrr == RRRR_DRD || $bin_rrrr == RRRR_DWR || $bin_rrrr == RRRR_PROBE) && 
                                          $bin_tt == TT_G &&                            $bin_ll == LL_L1 &&     $uc == $uc &&   $addrv == $addrv &&     $pcc == $pcc &&         $def == 0 &&    $poison == 0) 
                          {
                              $error_type = "Tag Error : Tag Array";
                              $addr = ($bin_rrrr == RRRR_PROBE) ? ($addr & 0xFFFFFFFFFFB0) >> 6 : ($addr & 0xFFFFFFFFFFF0) >> 4;
                              $addr_desc = "Physical";
                          }
                          
                          if($ext_errorcode == 0b10001 && $code_type eq "mem" && $bin_pp == $bin_pp && $bin_t == $bin_t     && $bin_rrrr == RRRR_DWR && 
                                          $bin_tt == TT_G &&                            $bin_ll == LL_L1 &&     $uc == $uc &&   $addrv == 1 &&          $pcc == 0 &&            $def == 0 &&    $poison == 0) 
                          {
                              $error_type = "Tag Error : STQ";
                              $addr = ($addr & 0xF) >> 0;
                              $addr_desc = "Index";
                          }
                          
                          if($ext_errorcode == 0b10010 && $code_type eq "mem" && $bin_pp == $bin_pp && $bin_t == $bin_t     && $bin_rrrr == RRRR_DRD && 
                                          $bin_tt == TT_G &&                            $bin_ll == LL_L1 &&     $uc == $uc &&   $addrv == 1 &&          $pcc == 0 &&            $def == 0 &&    $poison == 0) 
                          {
                              $error_type = "Tag Error : LDQ";
                              $addr = ($addr & 0x1F) >> 0;
                              $addr_desc = "Index";
                          }
                          
                          if($ext_errorcode == 0b00000 && $code_type eq "tlb" && $bin_pp == $bin_pp && $bin_t == $bin_t     && $bin_rrrr == $bin_rrrr && 
                                          $bin_tt == TT_D &&                            $bin_ll == LL_L1 &&     $uc == $uc &&   $addrv == 1 &&          $pcc == 0 &&            $def == 0 &&    $poison == 0) 
                          {
                              $error_type = "L1 TLB Error : TLB Parity";
                              $addr = ($addr & 0xFFFFFFFFF000) >> 12;
                              $addr_desc = "Linear";
                          }
                          
                          if($ext_errorcode == 0b00001 && $code_type eq "tlb" && $bin_pp == $bin_pp && $bin_t == $bin_t     && $bin_rrrr == $bin_rrrr && 
                                          $bin_tt == TT_D &&                            $bin_ll == LL_L1 &&     $uc == $uc &&   $addrv == 0 &&          $pcc == 0 &&            $def == 0 &&    $poison == 0) 
                          {
                              $error_type = "L1 TLB Error : TLB Multimatch";
                              $addr_desc = "N/A";
                          }
                          
                          if($ext_errorcode == 0b00010 && $code_type eq "tlb" && $bin_pp == $bin_pp && $bin_t == $bin_t     && $bin_rrrr == $bin_rrrr && 
                                          $bin_tt == TT_D &&                            $bin_ll == LL_L1 &&     $uc == 1 &&     $addrv == 1 &&          $pcc == 0 &&            $def == 0 &&    $poison == 0) 
                          {
                              $error_type = "L1 TLB Error : Locked TLB Miss";
                              $addr = ($addr & 0xFFFFFFFFF000) >> 12;
                              $addr_desc = "Linear";
                          }
                          
                          if($ext_errorcode == 0b00000 && $code_type eq "bus" && $bin_pp == PP_SRC  && $bin_t == T_0        && $bin_rrrr == RRRR_DRD && 
                                          ($bin_ii == II_MEM && $bin_ii == II_IO) &&    $bin_ll == LL_LG &&     $uc == 1 &&     $addrv == 1 &&          $pcc == 0 &&            $def == 0 &&    $poison == 0) 
                          {
                              $error_type = "System Read Data Error";
                              $addr = ($addr & 0xFFFFFFFFFFB0) >> 6;
                              $addr_desc = "Physical";
                          }
                          
                          if($ext_errorcode == 0b00001 && $code_type eq "bus" && $bin_pp == PP_GEN  && $bin_t == T_1        && $bin_rrrr == RRRR_GEN && 
                                          $bin_ii == II_GEN &&                          $bin_ll == LL_LG &&     $uc == 1 &&     $addrv == 0 &&          $pcc == 0 &&            $def == 0 &&    $poison == 0) 
                          {
                              $error_type = "Internal Error : Type 1";
                              $addr_desc = "N/A";
                          }
                          
                          if($ext_errorcode == 0b00010 && $code_type eq "bus" && $bin_pp == PP_GEN  && $bin_t == T_1        && $bin_rrrr == RRRR_GEN && 
                                          $bin_ii == II_GEN &&                          $bin_ll == LL_LG &&     $uc == 1 &&     $addrv == 0 &&          $pcc == 0 &&            $def == 0 &&    $poison == 0) 
                          {
                              $error_type = "Internal Error : Type 2";
                              $addr_desc = "N/A";
                          }
                          
			}
  if($bank == 1)	{# print "bank1 : $status\n"
			  $val = 		($status & 1 << 63) ? 1 : 0;
			  $ov = 		($status & 1 << 62) ? 1 : 0;
			  $uc =			($status & 1 << 61) ? 1 : 0;
			  $en = 		($status & 1 << 60) ? 1 : 0;
			  $miscv =		($status & 1 << 59) ? 1 : 0;
			  $addrv =		($status & 1 << 58) ? 1 : 0;
			  $pcc =		($status & 1 << 57) ? 1 : 0;
			  $cecc = 		"N/A";
			  $uecc = 		"N/A";
			  $def =		($status & 1 << 44) ? 1 : 0;
			  $poison =		($status & 1 << 43) ? 1 : 0;
			  $scrub =		"N/A";
			  $link =		"N/A";
			  $cache_way = 	        ($status & 0xF << 36) >> 36;
			  $syndrome = 		"N/A";
			  $core = 		"N/A";
			  $errorcode =		($status & 0xFFFF);
			  $ext_errorcode =	($status & 0x1F << 16) >> 16;
			  
			  # print "$cache_way, $errorcode, $ext_errorcode\tstatus = $status\n";

			  
			  ($code_type, $bin_tt, $bin_ll, $bin_rrrr, $bin_pp, $bin_t, $bin_ii) = decodeErrorCode($errorcode);
			  
			  if($ext_errorcode == 0b00000 && $code_type eq "mem" && $bin_pp == $bin_pp  && $bin_t == $bin_t        && $bin_rrrr == RRRR_IRD && 
                                          $bin_tt == TT_I &&    $bin_ll == LL_L2 &&     $uc == 1 &&     $addrv == 1 &&          $pcc == 0 &&            $def == 0 &&    $poison == 1) 
                          {
                              $error_type = "Line Fill Error";
                          }
                          if($ext_errorcode == 0b00001 && $code_type eq "mem" && $bin_pp == $bin_pp  && $bin_t == $bin_t        && $bin_rrrr == RRRR_IRD && 
                                          $bin_tt == TT_I &&    $bin_ll == LL_L1 &&     $uc == 0 &&     $addrv == 1 &&          $pcc == 0 &&            $def == 0 &&    $poison == 0) 
                          {
                              $error_type = "Instruction Cache Read Error : IC data load parity";
                          }
                          if($ext_errorcode == 0b00010 && $code_type eq "mem" && $bin_pp == $bin_pp  && $bin_t == $bin_t        && $bin_rrrr == RRRR_IRD && 
                                          $bin_tt == TT_I &&    $bin_ll == LL_L1 &&     $uc == 0 &&     $addrv == 1 &&          $pcc == 0 &&            $def == 0 &&    $poison == 0) 
                          {
                              $error_type = "Instruction Cache Read Error : IC valid bit";
                          }
                          if($ext_errorcode == 0b00011 && $code_type eq "mem" && $bin_pp == $bin_pp  && $bin_t == $bin_t        && $bin_rrrr == RRRR_IRD && 
                                          $bin_tt == TT_I &&    $bin_ll == LL_L1 &&     $uc == 0 &&     $addrv == 1 &&          $pcc == 0 &&            $def == 0 &&    $poison == 0) 
                          {
                              $error_type = "Instruction Cache Read Error : Main Tag";
                          }
                          if($ext_errorcode == 0b00100 && $code_type eq "mem" && $bin_pp == $bin_pp  && $bin_t == $bin_t        && $bin_rrrr == RRRR_IRD && 
                                          $bin_tt == TT_I &&    $bin_ll == LL_L1 &&     $uc == 1 &&     $addrv == 0 &&          $pcc == 0 &&            $def == 0 &&    $poison == 0) 
                          {
                              $error_type = "Instruction Cache Read Error : Prediction Queue";
                          }
                          if($ext_errorcode == 0b00101 && $code_type eq "mem" && $bin_pp == $bin_pp  && $bin_t == $bin_t        && $bin_rrrr == RRRR_IRD && 
                                          $bin_tt == TT_I &&    $bin_ll == LL_L1 &&     $uc == $uc &&     $addrv == 0 &&          $pcc == 0 &&            $def == 0 &&    $poison == 0) 
                          {
                              $error_type = "Instruction Cache Read Error : PFB data/address";
                          }
                          if($ext_errorcode == 0b01101 && $code_type eq "mem" && $bin_pp == $bin_pp  && $bin_t == $bin_t        && $bin_rrrr == RRRR_IRD && 
                                          $bin_tt == TT_I &&    $bin_ll == LL_L1 &&     $uc == 1 &&     $addrv == 0 &&          $pcc == 0 &&            $def == 0 &&    $poison == 0) 
                          {
                              $error_type = "Instruction Cache Read Error : PFB valid bit";
                          }
                          if($ext_errorcode == 0b01010 && $code_type eq "mem" && $bin_pp == $bin_pp  && $bin_t == $bin_t        && $bin_rrrr == RRRR_IRD && 
                                          $bin_tt == TT_I &&    $bin_ll == LL_L1 &&     $uc == $uc &&     $addrv == 0 &&          $pcc == 0 &&            $def == 0 &&    $poison == 0) 
                          {
                              $error_type = "Instruction Cache Read Error : PFB non-cacheable bit";
                          }
                          if($ext_errorcode == 0b00111 && $code_type eq "mem" && $bin_pp == $bin_pp  && $bin_t == $bin_t        && $bin_rrrr == RRRR_IRD && 
                                          $bin_tt == TT_I &&    $bin_ll == LL_L1 &&     $uc == 1 &&     $addrv == 0 &&          $pcc == 1 &&            $def == 0 &&    $poison == 0) 
                          {
                              $error_type = "Instruction Cache Read Error : PFB promotion address error";
                          }
                          if($ext_errorcode == 0b00110 && $code_type eq "mem" && $bin_pp == $bin_pp  && $bin_t == $bin_t        && $bin_rrrr == RRRR_IRD && 
                                          $bin_tt == TT_I &&    $bin_ll == LL_L1 &&     $uc == 1 &&     $addrv == 0 &&          $pcc == 0 &&            $def == 0 &&    $poison == 0) 
                          {
                              $error_type = "Instruction Cache Read Error : Branch Status Register";
                          }
                          if($ext_errorcode == 0b10000 && $code_type eq "mem" && $bin_pp == $bin_pp  && $bin_t == $bin_t        && $bin_rrrr == RRRR_IRD && 
                                          $bin_tt == TT_I &&    $bin_ll == LL_LG &&     $uc == 1 &&     $addrv == 1 &&          $pcc == 1 &&            $def == 0 &&    $poison == 0) 
                          {
                              $error_type = "Instruction Cache Read Error : Micro code patch buffer";
                          }
                          if($ext_errorcode == 0b10001 && $code_type eq "mem" && $bin_pp == $bin_pp  && $bin_t == $bin_t        && $bin_rrrr == RRRR_IRD && 
                                          $bin_tt == TT_I &&    $bin_ll == LL_L1 &&     $uc == $uc &&     $addrv == 1 &&          $pcc == 0 &&            $def == 0 &&    $poison == 0) 
                          {
                              $error_type = "Instruction Cache Read Error : Decoder micro-op queue";
                          }
                          if($ext_errorcode == 0b10010 && $code_type eq "mem" && $bin_pp == $bin_pp  && $bin_t == $bin_t        && $bin_rrrr == RRRR_IRD && 
                                          $bin_tt == TT_I &&    $bin_ll == LL_L1 &&     $uc == $uc &&     $addrv == 1 &&          $pcc == 0 &&            $def == 0 &&    $poison == 0) 
                          {
                              $error_type = "Instruction Cache Read Error : Decoder Instruction buffer";
                          }
                          if($ext_errorcode == 0b10011 && $code_type eq "mem" && $bin_pp == $bin_pp  && $bin_t == $bin_t        && $bin_rrrr == RRRR_IRD && 
                                          $bin_tt == TT_I &&    $bin_ll == LL_L1 &&     $uc == $uc &&     $addrv == 0 &&          $pcc == 0 &&            $def == 0 &&    $poison == 0) 
                          {
                              $error_type = "Instruction Cache Read Error : Decoder predecode buffer";
                          }
                          if($ext_errorcode == 0b10100 && $code_type eq "mem" && $bin_pp == $bin_pp  && $bin_t == $bin_t        && $bin_rrrr == RRRR_IRD && 
                                          $bin_tt == TT_I &&    $bin_ll == LL_L1 &&     $uc == $uc &&     $addrv == 1 &&          $pcc == 0 &&            $def == 0 &&    $poison == 0) 
                          {
                              $error_type = "Instruction Cache Read Error : Decoder fetch address FIFO";
                          }
                          if($ext_errorcode == 0b01000 && $code_type eq "mem" && $bin_pp == $bin_pp  && $bin_t == $bin_t        && $bin_rrrr == RRRR_PROBE && 
                                          $bin_tt == TT_I &&    $bin_ll == LL_L1 &&     $uc == 0 &&     $addrv == 1 &&          $pcc == 0 &&            $def == 0 &&    $poison == 0) 
                          {
                              $error_type = "Tag Probe : Probe Tag error";
                          }
                          if($ext_errorcode == 0b01001 && $code_type eq "mem" && $bin_pp == $bin_pp  && $bin_t == $bin_t        && $bin_rrrr == RRRR_PROBE && 
                                          $bin_tt == TT_I &&    $bin_ll == LL_L1 &&     $uc == 0 &&     $addrv == 1 &&          $pcc == 0 &&            $def == 0 &&    $poison == 0) 
                          {
                              $error_type = "Tag Probe : Probe Tag valid bit";
                          }
                          if($ext_errorcode == 0b00000 && $code_type eq "tlb" && $bin_pp == $bin_pp  && $bin_t == $bin_t        && $bin_rrrr == $bin_rrrr && 
                                          $bin_tt == TT_I &&    $bin_ll == LL_L1 &&     $uc == 0 &&     $addrv == 1 &&          $pcc == 0 &&            $def == 0 &&    $poison == 0) 
                          {
                              $error_type = "L1 TLB : Parity";
                          }
                          if($ext_errorcode == 0b00001 && $code_type eq "tlb" && $bin_pp == $bin_pp  && $bin_t == $bin_t        && $bin_rrrr == $bin_rrrr && 
                                          $bin_tt == TT_I &&    $bin_ll == LL_L1 &&     $uc == 0 &&     $addrv == 1 &&          $pcc == 0 &&            $def == 0 &&    $poison == 0) 
                          {
                              $error_type = "L1 TLB : Multimatch";
                          }
                          if($ext_errorcode == 0b00000 && $code_type eq "tlb" && $bin_pp == $bin_pp  && $bin_t == $bin_t        && $bin_rrrr == $bin_rrrr && 
                                          $bin_tt == TT_I &&    $bin_ll == LL_L2 &&     $uc == 0 &&     $addrv == 1 &&          $pcc == 0 &&            $def == 0 &&    $poison == 0) 
                          {
                              $error_type = "L2 TLB : Parity";
                          }
                          if($ext_errorcode == 0b00001 && $code_type eq "tlb" && $bin_pp == $bin_pp  && $bin_t == $bin_t        && $bin_rrrr == $bin_rrrr && 
                                          $bin_tt == TT_I &&    $bin_ll == LL_L2 &&     $uc == 0 &&     $addrv == 1 &&          $pcc == 0 &&            $def == 0 &&    $poison == 0) 
                          {
                              $error_type = "L2 TLB : Multimatch";
                          }
                          if($ext_errorcode == 0b00000 && $code_type eq "bus" && $bin_pp == PP_SRC  && $bin_t == T_0        && $bin_rrrr == RRRR_IRD && 
                                          $bin_ii == II_MEM &&    $bin_ll == LL_LG &&     $uc == 1 &&     $addrv == 1 &&          $pcc == 0 &&            $def == 0 &&    $poison == 0) 
                          {
                              $error_type = "System read data error";
                          }

			}
  if($bank == 2)	{# print "bank2 : $status\n"
			  $val = 		($status & 1 << 63) ? 1 : 0;
			  $ov = 		($status & 1 << 62) ? 1 : 0;
			  $uc =			($status & 1 << 61) ? 1 : 0;
			  $en = 		($status & 1 << 60) ? 1 : 0;
			  $miscv =		($status & 1 << 59) ? 1 : 0;
			  $addrv =		($status & 1 << 58) ? 1 : 0;
			  $pcc =		($status & 1 << 57) ? 1 : 0;
			  $errCoreVal =	        "N/A";
			  $cecc = 		($status & 1 << 46) ? 1 : 0;
			  $uecc = 		($status & 1 << 45) ? 1 : 0;
			  $def =		($status & 1 << 44) ? 1 : 0;
			  $poison =		($status & 1 << 43) ? 1 : 0;
			  $scrub =		"N/A";
			  $link =		"N/A";
			  $cache_way = 	        ($status & 0xF << 36) >> 36;
			  $syndrome = 		($status & 0xF << 24) >> 16 | ($status & 0xFF << 47) >> 47;
			  $core = 		"N/A";
			  $errorcode =		($status & 0xFFFF);
			  $ext_errorcode =	($status & 0x1F << 16) >> 16;
			  
			  # print "$cache_way, $errorcode, $ext_errorcode\n";

			  
			  ($code_type, $bin_tt, $bin_ll, $bin_rrrr, $bin_pp, $bin_t, $bin_ii) = decodeErrorCode($errorcode);
			  
			  if($ext_errorcode == 0b00000 &&   $code_type eq "tlb" &&  $bin_pp == $bin_pp &&   $bin_t == $bin_t     &&         $bin_rrrr == $bin_rrrr && 
                                          $bin_tt == TT_G &&  $bin_ll == LL_L2 &&     $uc == 0 &&     $addrv == 1 &&          $pcc == 0 && $cecc == 0 && $uecc == 0 && $def == 0 && $poison == 0) 
                          {
                              $error_type = "TLB : TLbpar" ;
                              $addr = ($addr & 0xFFFFFFFFFFFE) >> 1;
                              $addr_desc = "Physical";
                              $cache_way = $cache_way & 0x3;
                              $core = "N/A";  
                              $syndrome = "N/A";                            
                          }
                          if($ext_errorcode == 0b00001 &&   $code_type eq "tlb" &&  $bin_pp == $bin_pp &&   $bin_t == $bin_t     &&         $bin_rrrr == $bin_rrrr && 
                                          $bin_tt == TT_G &&  $bin_ll == LL_L2 &&     $uc == 1 &&     $addrv == 1 &&          $pcc == 0 && $cecc == 0 && $uecc == 0 && $def == 0 && $poison == 1) 
                          {
                              $error_type = "TLB Error : Fillerr" ;
                              $addr = ($addr & 0xFFFFFFFFFFFE) >> 1;
                              $addr_desc = "Physical";
                              $cache_way = "N/A";
                              $core = "N/A";  
                              $syndrome = "N/A";                            
                          }
                          if($ext_errorcode == 0b00000 &&   $code_type eq "bus" &&  $bin_pp == PP_SRC &&   $bin_t == T_0     &&         $bin_rrrr == RRRR_RD && 
                                          ($bin_ii == II_MEM || $bin_ii == II_IO) &&  $bin_ll == LL_L2 &&     $uc == 1 &&     $addrv == 1 &&          $pcc == 0 && $cecc == 0 && $uecc == 0 && $def == 0 && $poison == 0) 
                          {
                              $error_type = "System Read Data Error : L2Tlb" ;
                              $addr = ($addr & 0xFFFFFFFFFFFE) >> 1;
                              $addr_desc = "Physical";
                              $cache_way = "N/A";
                              $core = "N/A";  
                              $syndrome = "N/A";                            
                          }
                          if($ext_errorcode == 0b00001 &&   $code_type eq "bus" &&  $bin_pp == PP_SRC &&   $bin_t == T_0     &&         $bin_rrrr == RRRR_RD && 
                                          $bin_ii == II_MEM &&  $bin_ll == LL_L2 &&     $uc == 0 &&     $addrv == 1 &&          $pcc == 0 && $cecc == 0 && $uecc == 0 && $def == 0 && $poison == 0) 
                          {
                              $error_type = "System Read Data Error : Prefetch" ;
                              $addr = ($addr & 0xFFFFFFFFFFFE) >> 1;
                              $addr_desc = "Physical";
                              $cache_way = "N/A";
                              $core = "N/A";  
                              $syndrome = "N/A";                            
                          }
                          if($ext_errorcode == 0b00010 &&   $code_type eq "bus" &&  $bin_pp == PP_SRC &&   $bin_t == T_0     &&         $bin_rrrr == RRRR_DWR && 
                                          $bin_ii == II_MEM &&  $bin_ll == LL_L1 &&     $uc == 1 &&     $addrv == 1 &&          $pcc == 0 && $cecc == 0 && $uecc == 0 && $def == 0 && $poison == 0) 
                          {
                              $error_type = "System Read Data Error : Wcc" ;
                              $addr = ($addr & 0xFFFFFFFFFFFE) >> 1;
                              $addr_desc = "Physical";
                              $cache_way = "N/A";
                              $core = "N/A";  
                              $syndrome = "N/A";                            
                          }
                          if($ext_errorcode == 0b00100 &&   $code_type eq "mem" &&  $bin_pp == $bin_pp &&   $bin_t == $bin_t     &&         $bin_rrrr == RRRR_DRD && 
                                          $bin_tt == TT_D &&  $bin_ll > 0 &&     $uc == 0 &&     $addrv == 1 &&          $pcc == 0 && $cecc == 0 && $uecc == 1 && $def == 1 && $poison == 0) 
                          {                              
                              my $source = ($bin_ll == LL_L1) ? "WCC" : (($bin_ll == LL_L2) ? "L2" : "NB");
                              $error_type = "L2 Cache Error : FillEcc : MBE, Source is ".$source ;
                              $addr = ($addr & 0xFFFFFFFFFFFE) >> 1;
                              $addr_desc = "Physical";
                              $cache_way = ($bin_ll == LL_L1) ? $cache_way & 0x3 : (($bin_ll == LL_L2) ? $cache_way & 0xF : "N/A");
                              $core = "N/A";  
                              $syndrome = $syndrome &  0xFF;                            
                          }
                          if($ext_errorcode == 0b00100 &&   $code_type eq "mem" &&  $bin_pp == $bin_pp &&   $bin_t == $bin_t     &&         $bin_rrrr == RRRR_DRD && 
                                          $bin_tt == TT_D &&  $bin_ll > 0 &&     $uc == 0 &&     $addrv == 1 &&          $pcc == 0 && $cecc == 1 && $uecc == 0 && $def == 1 && $poison == 0) 
                          {                              
                              my $source = ($bin_ll == LL_L1) ? "WCC" : (($bin_ll == LL_L2) ? "L2" : "NB");
                              $error_type = "L2 Cache Error : FillEcc : SBU, Source is ".$source ;
                              $addr = ($addr & 0xFFFFFFFFFFFE) >> 1;
                              $addr_desc = "Physical";
                              $cache_way = ($bin_ll == LL_L1) ? $cache_way & 0x3 : (($bin_ll == LL_L2) ? $cache_way & 0xF : "N/A");
                              $core = "N/A";  
                              $syndrome = $syndrome &  0xFF;                            
                          }
                          if($ext_errorcode == 0b00100 &&   $code_type eq "mem" &&  $bin_pp == $bin_pp &&   $bin_t == $bin_t     &&         $bin_rrrr == RRRR_DRD && 
                                          $bin_tt == TT_D &&  $bin_ll > 0 &&     $uc == 0 &&     $addrv == 1 &&          $pcc == 0 && $cecc == 1 && $uecc == 0 && $def == 0 && $poison == 0) 
                          {                              
                              my $source = ($bin_ll == LL_L1) ? "WCC" : (($bin_ll == LL_L2) ? "L2" : "NB");
                              $error_type = "L2 Cache Error : FillEcc : SBC, Source is ".$source ;
                              $addr = ($addr & 0xFFFFFFFFFFFE) >> 1;
                              $addr_desc = "Physical";
                              $cache_way = ($bin_ll == LL_L1) ? $cache_way & 0x3 : (($bin_ll == LL_L2) ? $cache_way & 0xF : "N/A");
                              $core = "N/A";  
                              $syndrome = $syndrome &  0xFF;                            
                          }
                          if($ext_errorcode == 0b00101 &&   $code_type eq "mem" &&  $bin_pp == $bin_pp &&   $bin_t == $bin_t     &&         $bin_rrrr == RRRR_IRD && 
                                          $bin_tt == TT_I &&  $bin_ll == LL_LG &&     $uc == 0 &&     $addrv == 0 &&          $pcc == 0 && $cecc == 0 && $uecc == 0 && $def == 0 && $poison == 0) 
                          {
                              $error_type = "L2 Cache Error : FillPar : NB->IC" ;
                              $addr = ($addr & 0xFFFFFFFFFFFE) >> 1;
                              $addr_desc = "Physical";
                              $cache_way = "N/A";
                              $core = "N/A";  
                              $syndrome = "N/A";                            
                          }
                          if($ext_errorcode == 0b00101 &&   $code_type eq "mem" &&  $bin_pp == $bin_pp &&   $bin_t == $bin_t     &&         $bin_rrrr == RRRR_IRD && 
                                          $bin_tt == TT_I &&  $bin_ll == LL_L2 &&     $uc == 0 &&     $addrv == 0 &&          $pcc == 0 && $cecc == 0 && $uecc == 0 && $def == 0 && $poison == 0) 
                          {
                              $error_type = "L2 Cache Error : FillPar : L2->IC" ;
                              $addr = ($addr & 0xFFFFFFFFFFFE) >> 1;
                              $addr_desc = "Physical";
                              $cache_way = "N/A";
                              $core = "N/A";  
                              $syndrome = "N/A";                            
                          }
                          if($ext_errorcode == 0b00101 &&   $code_type eq "mem" &&  $bin_pp == $bin_pp &&   $bin_t == $bin_t     &&         $bin_rrrr == RRRR_DRD && 
                                          $bin_tt == TT_D &&  $bin_ll == LL_L2 &&     $uc == 0 &&     $addrv == 1 &&          $pcc == 0 && $cecc == 0 && $uecc == 0 && $def == 1 && $poison == 0) 
                          {
                              $error_type = "L2 Cache Error : FillPar : L2->(LS, TLB)" ;
                              $addr = ($addr & 0xFFFFFFFFFFFE) >> 1;
                              $addr_desc = "Physical";
                              $cache_way = $cache_way & 0xF;
                              $core = "N/A";  
                              $syndrome = "N/A";                            
                          }
                          if($ext_errorcode == 0b00110 &&   $code_type eq "mem" &&  $bin_pp == $bin_pp &&   $bin_t == $bin_t     &&         $bin_rrrr == RRRR_PREFETCH && 
                                          $bin_tt == TT_D &&  $bin_ll == LL_L2 &&     $uc == 0 &&     $addrv == 1 &&          $pcc == 0 && $cecc == 0 && $uecc == 0 && $def == 0 && $poison == 0) 
                          {
                              $error_type = "L2 Cache Error : Prefetch";
                              $addr = ($addr & 0xFFFFFFFFFFFE) >> 1;
                              $addr_desc = "Physical";
                              $cache_way = "N/A";
                              $core = "N/A";  
                              $syndrome = "N/A";                            
                          }
                          if($ext_errorcode == 0b00111 &&   $code_type eq "mem" &&  $bin_pp == $bin_pp &&   $bin_t == $bin_t     &&         $bin_rrrr == RRRR_DWR && 
                                          $bin_tt == TT_D &&  $bin_ll == LL_L1 &&     $uc == 1 &&     $addrv == 0 &&          $pcc == 1 && $cecc == 0 && $uecc == 0 && $def == 0 && $poison == 0) 
                          {
                              $error_type = "L2 Cache Error : PrqAddr";
                              $addr = ($addr & 0xFFFFFFFFFFFE) >> 1;
                              $addr_desc = "Physical";
                              $cache_way = "N/A";
                              $core = "N/A";  
                              $syndrome = "N/A";                            
                          }
                          if($ext_errorcode == 0b01000 &&   $code_type eq "mem" &&  $bin_pp == $bin_pp &&   $bin_t == $bin_t     &&         $bin_rrrr == RRRR_DWR && 
                                          $bin_tt == TT_D &&  $bin_ll == LL_L1 &&     $uc == 0 &&     $addrv == 0 &&          $pcc == 0 && $cecc == 0 && $uecc == 0 && $def == 1 && $poison == 0) 
                          {
                              $error_type = "L2 Cache Error : PrqData";
                              $addr = ($addr & 0xFFFFFFFFFFFE) >> 1;
                              $addr_desc = "Physical";
                              $cache_way = "N/A";
                              $core = "N/A";  
                              $syndrome = "N/A";                            
                          }
                          if($ext_errorcode == 0b01001 &&   $code_type eq "mem" &&  $bin_pp == $bin_pp &&   $bin_t == $bin_t     &&         $bin_rrrr == RRRR_DWR && 
                                          $bin_tt == TT_D &&  $bin_ll == LL_L1 &&     $uc == 1 &&     $addrv == 1 &&          $pcc == 1 && $cecc == 0 && $uecc == 1 && $def == 0 && $poison == 0) 
                          {
                              $error_type = "L2 Cache Error : WccTag : MBE";
                              $addr = ($addr & 0xFFFFFFFFFFFE) >> 1;
                              $addr_desc = "Physical";
                              $cache_way = $cache_way & 0x3;
                              $core = "N/A";  
                              $syndrome = $syndrome & 0xFFF;                            
                          }
                          if($ext_errorcode == 0b01001 &&   $code_type eq "mem" &&  $bin_pp == $bin_pp &&   $bin_t == $bin_t     &&         $bin_rrrr == RRRR_DWR && 
                                          $bin_tt == TT_D &&  $bin_ll == LL_L1 &&     $uc == 1 &&     $addrv == 1 &&          $pcc == 1 && $cecc == 1 && $uecc == 0 && $def == 0 && $poison == 0) 
                          {
                              $error_type = "L2 Cache Error : WccTag : SBU";
                              $addr = ($addr & 0xFFFFFFFFFFFE) >> 1;
                              $addr_desc = "Physical";
                              $cache_way = $cache_way & 0x3;
                              $core = "N/A";  
                              $syndrome = $syndrome & 0xFFF;                            
                          }
                          if($ext_errorcode == 0b01001 &&   $code_type eq "mem" &&  $bin_pp == $bin_pp &&   $bin_t == $bin_t     &&         $bin_rrrr == RRRR_DWR && 
                                          $bin_tt == TT_D &&  $bin_ll == LL_L1 &&     $uc == 0 &&     $addrv == 1 &&          $pcc == 0 && $cecc == 1 && $uecc == 0 && $def == 0 && $poison == 0) 
                          {
                              $error_type = "L2 Cache Error : WccTag : SBC";
                              $addr = ($addr & 0xFFFFFFFFFFFE) >> 1;
                              $addr_desc = "Physical";
                              $cache_way = $cache_way & 0x3;
                              $core = "N/A";  
                              $syndrome = $syndrome & 0xFFF;                            
                          }
                          if($ext_errorcode == 0b01010 &&   $code_type eq "mem" &&  $bin_pp == $bin_pp &&   $bin_t == $bin_t     &&         $bin_rrrr == RRRR_DWR && 
                                          $bin_tt == TT_D &&  $bin_ll == LL_L1 &&     $uc == 0 &&     $addrv == 1 &&          $pcc == 0 && $cecc == 0 && $uecc == 1 && $def == 1 && $poison == 0) 
                          {
                              $error_type = "L2 Cache Error : WccData : MBE";
                              $addr = ($addr & 0xFFFFFFFFFFFE) >> 1;
                              $addr_desc = "Physical";
                              $cache_way = $cache_way & 0x3;
                              $core = "N/A";  
                              $syndrome = $syndrome & 0xFF;                            
                          }
                          if($ext_errorcode == 0b01010 &&   $code_type eq "mem" &&  $bin_pp == $bin_pp &&   $bin_t == $bin_t     &&         $bin_rrrr == RRRR_DWR && 
                                          $bin_tt == TT_D &&  $bin_ll == LL_L1 &&     $uc == 0 &&     $addrv == 1 &&          $pcc == 0 && $cecc == 1 && $uecc == 0 && $def == 1 && $poison == 0) 
                          {
                              $error_type = "L2 Cache Error : WccData : SBU";
                              $addr = ($addr & 0xFFFFFFFFFFFE) >> 1;
                              $addr_desc = "Physical";
                              $cache_way = $cache_way & 0x3;
                              $core = "N/A";  
                              $syndrome = $syndrome & 0xFF;                            
                          }
                          if($ext_errorcode == 0b01010 &&   $code_type eq "mem" &&  $bin_pp == $bin_pp &&   $bin_t == $bin_t     &&         $bin_rrrr == RRRR_DWR && 
                                          $bin_tt == TT_D &&  $bin_ll == LL_L1 &&     $uc == 0 &&     $addrv == 1 &&          $pcc == 0 && $cecc == 1 && $uecc == 0 && $def == 0 && $poison == 0) 
                          {
                              $error_type = "L2 Cache Error : WccData : SBC";
                              $addr = ($addr & 0xFFFFFFFFFFFE) >> 1;
                              $addr_desc = "Physical";
                              $cache_way = $cache_way & 0x3;
                              $core = "N/A";  
                              $syndrome = $syndrome & 0xFF;                            
                          }
                          if($ext_errorcode == 0b01011 &&   $code_type eq "mem" &&  $bin_pp == $bin_pp &&   $bin_t == $bin_t     &&         $bin_rrrr == RRRR_DWR && 
                                          $bin_tt == TT_D &&  $bin_ll == LL_LG &&     $uc == 0 &&     $addrv == 1 &&          $pcc == 0 && $cecc == 0 && $uecc == 0 && $def == 1 && $poison == 0) 
                          {
                              $error_type = "L2 Cache Error : WcbData";
                              $addr = ($addr & 0xFFFFFFFFFFFE) >> 1;
                              $addr_desc = "Physical";
                              $cache_way = $cache_way & 0x3;
                              $core = "N/A";  
                              $syndrome = $syndrome & 0xFF;                            
                          }
                          if($ext_errorcode == 0b01100 &&   $code_type eq "mem" &&  $bin_pp == $bin_pp &&   $bin_t == $bin_t     &&         ($bin_rrrr == RRRR_PROBE || $bin_rrrr == RRRR_EVICT) && 
                                          $bin_tt == TT_I &&  $bin_ll == LL_L2 &&     $uc == 0 &&     $addrv == 0 &&          $pcc == 0 && $cecc == 0 && $uecc == 0 && $def == 1 && $poison == 0) 
                          {
                              $error_type = "L2 Cache Error : VbData : Par";
                              $addr = ($addr & 0xFFFFFFFFFFFE) >> 1;
                              $addr_desc = "Physical";
                              $cache_way = "N/A";
                              $core = "N/A";  
                              $syndrome = "N/A";                            
                          }
                          if($ext_errorcode == 0b01100 &&   $code_type eq "mem" &&  $bin_pp == $bin_pp &&   $bin_t == $bin_t     &&         ($bin_rrrr == RRRR_PROBE || $bin_rrrr == RRRR_EVICT) && 
                                          $bin_tt == TT_D &&  $bin_ll == LL_L2 &&     $uc == 0 &&     $addrv == 0 &&          $pcc == 0 && $cecc == 0 && $uecc == 1 && $def == 1 && $poison == 0) 
                          {
                              $error_type = "L2 Cache Error : VbData : MBE";
                              $addr = ($addr & 0xFFFFFFFFFFFE) >> 1;
                              $addr_desc = "Physical";
                              $cache_way = "N/A";
                              $core = "N/A";  
                              $syndrome = $syndrome & 0xFF;                            
                          }
                          if($ext_errorcode == 0b01100 &&   $code_type eq "mem" &&  $bin_pp == $bin_pp &&   $bin_t == $bin_t     &&         ($bin_rrrr == RRRR_PROBE || $bin_rrrr == RRRR_EVICT) && 
                                          $bin_tt == TT_D &&  $bin_ll == LL_L2 &&     $uc == 0 &&     $addrv == 0 &&          $pcc == 0 && $cecc == 1 && $uecc == 0 && $def == 1 && $poison == 0) 
                          {
                              $error_type = "L2 Cache Error : VbData : SBU";
                              $addr = ($addr & 0xFFFFFFFFFFFE) >> 1;
                              $addr_desc = "Physical";
                              $cache_way = "N/A";
                              $core = "N/A";  
                              $syndrome = $syndrome & 0xFF;                            
                          }
                          if($ext_errorcode == 0b01100 &&   $code_type eq "mem" &&  $bin_pp == $bin_pp &&   $bin_t == $bin_t     &&         ($bin_rrrr == RRRR_PROBE || $bin_rrrr == RRRR_EVICT) && 
                                          $bin_tt == TT_D &&  $bin_ll == LL_L2 &&     $uc == 0 &&     $addrv == 0 &&          $pcc == 0 && $cecc == 1 && $uecc == 0 && $def == 0 && $poison == 0) 
                          {
                              $error_type = "L2 Cache Error : VbData : SBC";
                              $addr = ($addr & 0xFFFFFFFFFFFE) >> 1;
                              $addr_desc = "Physical";
                              $cache_way = "N/A";
                              $core = "N/A";  
                              $syndrome = $syndrome & 0xFF;                            
                          }
                          if($ext_errorcode == 0b10000 &&   $code_type eq "mem" &&  $bin_pp == $bin_pp &&   $bin_t == $bin_t     &&         $bin_rrrr == RRRR_GEN && 
                                          $bin_tt == TT_G &&  $bin_ll == LL_L2 &&     $uc == 1 &&     $addrv == 1 &&          $pcc == 1 && $cecc == 0 && $uecc == 1 && $def == 0 && $poison == 0) 
                          {
                              $error_type = "Tag : L2Tag : MBE";
                              $addr = ($addr & 0xFFFFFFFFFFFE) >> 1;
                              $addr_desc = "Physical";
                              $cache_way = $cache_way & 0xF;
                              $core = "N/A";  
                              $syndrome = $syndrome & 0xFF;                            
                          }
                          if($ext_errorcode == 0b10000 &&   $code_type eq "mem" &&  $bin_pp == $bin_pp &&   $bin_t == $bin_t     &&         $bin_rrrr == RRRR_GEN && 
                                          $bin_tt == TT_G &&  $bin_ll == LL_L2 &&     $uc == 1 &&     $addrv == 1 &&          $pcc == 1 && $cecc == 1 && $uecc == 0 && $def == 0 && $poison == 0) 
                          {
                              $error_type = "Tag : L2Tag : SBU";
                              $addr = ($addr & 0xFFFFFFFFFFFE) >> 1;
                              $addr_desc = "Physical";
                              $cache_way = $cache_way & 0xF;
                              $core = "N/A";  
                              $syndrome = $syndrome & 0xFF;                            
                          }
                          if($ext_errorcode == 0b10000 &&   $code_type eq "mem" &&  $bin_pp == $bin_pp &&   $bin_t == $bin_t     &&         $bin_rrrr == RRRR_GEN && 
                                          $bin_tt == TT_G &&  $bin_ll == LL_L2 &&     $uc == 0 &&     $addrv == 1 &&          $pcc == 0 && $cecc == 1 && $uecc == 0 && $def == 0 && $poison == 0) 
                          {
                              $error_type = "Tag : L2Tag : SBC";
                              $addr = ($addr & 0xFFFFFFFFFFFE) >> 1;
                              $addr_desc = "Physical";
                              $cache_way = $cache_way & 0xF;
                              $core = "N/A";  
                              $syndrome = $syndrome & 0xFF;                            
                          }
                          if($ext_errorcode == 0b10001 &&   $code_type eq "mem" &&  $bin_pp == $bin_pp &&   $bin_t == $bin_t     &&         $bin_rrrr == RRRR_GEN && 
                                          $bin_tt == TT_G &&  $bin_ll == LL_L2 &&     $uc == 1 &&     $addrv == 1 &&          $pcc == 1 && $cecc == 0 && $uecc == 0 && $def == 0 && $poison == 0) 
                          {
                              $error_type = "Tag : L2Tag : Hard";
                              $addr = ($addr & 0xFFFFFFFFFFFE) >> 1;
                              $addr_desc = "Physical";
                              $cache_way = $cache_way & 0xF;
                              $core = "N/A";  
                              $syndrome = $syndrome & 0xFF;                            
                          }
                          if($ext_errorcode == 0b10010 &&   $code_type eq "mem" &&  $bin_pp == $bin_pp &&   $bin_t == $bin_t     &&         $bin_rrrr == RRRR_GEN && 
                                          $bin_tt == TT_G &&  $bin_ll == LL_L2 &&     $uc == 1 &&     $addrv == 1 &&          $pcc == 1 && $cecc == 0 && $uecc == 0 && $def == 0 && $poison == 0) 
                          {
                              $error_type = "Tag : L2TagMH";
                              $addr = ($addr & 0xFFFFFFFFFFFE) >> 1;
                              $addr_desc = "Physical";
                              $cache_way = "N/A";
                              $core = "N/A";  
                              $syndrome = "N/A";                            
                          }
                          if($ext_errorcode == 0b10011 &&   $code_type eq "mem" &&  $bin_pp == $bin_pp &&   $bin_t == $bin_t     &&         $bin_rrrr == RRRR_GEN && 
                                          $bin_tt == TT_G &&  $bin_ll == LL_L2 &&     $uc == 1 &&     $addrv == 1 &&          $pcc == 1 && $cecc == 0 && $uecc == 0 && $def == 0 && $poison == 0) 
                          {
                              $error_type = "Tag : XabAddr";
                              $addr = ($addr & 0xFFFFFFFFFFFE) >> 1;
                              $addr_desc = "Physical";
                              $cache_way = "N/A";
                              $core = "N/A";  
                              $syndrome = "N/A";                           
                          }
                          if($ext_errorcode == 0b10100 &&   $code_type eq "mem" &&  $bin_pp == $bin_pp &&   $bin_t == $bin_t     &&         $bin_rrrr == RRRR_PROBE && 
                                          $bin_tt == TT_G &&  $bin_ll == LL_L2 &&     $uc == 1 &&     $addrv == 1 &&          $pcc == 1 && $cecc == 0 && $uecc == 0 && $def == 0 && $poison == 0) 
                          {
                              $error_type = "Tag : PrbAddr";
                              $addr = ($addr & 0xFFFFFFFFFFFE) >> 1;
                              $addr_desc = "Physical";
                              $cache_way = "N/A";
                              $core = "N/A";  
                              $syndrome = "N/A";                           
                          }


			}
  if($bank == 4)	{# print "bank4 : $status\n"
			  $val = 		($status & 1 << 63) ? 1 : 0;
			  $ov = 		($status & 1 << 62) ? 1 : 0;
			  $uc =			($status & 1 << 61) ? 1 : 0;
			  $en = 		($status & 1 << 60) ? 1 : 0;
			  $miscv =		($status & 1 << 59) ? 1 : 0;
			  $addrv =		($status & 1 << 58) ? 1 : 0;
			  $pcc =		($status & 1 << 57) ? 1 : 0;
			  $errCoreVal =	        ($status & 1 << 56) ? 1 : 0;
			  $cecc = 		($status & 1 << 46) ? 1 : 0;
			  $uecc = 		($status & 1 << 45) ? 1 : 0;
			  $def =		"N/A";
			  $poison =		"N/A";
			  $l3_subcache =        ($status & 0x3 << 42) >> 42;
			  $sublink =            ($status & 1 << 41) ? 1 : 0;
			  $scrub =		($status & 1 << 40) ? 1 : 0;
			  $link =		($status & 0xF << 36) >> 36;
			  $cache_way = 	        "N/A";
			  $syndrome = 		($status & 0xFF << 24) >> 16 | ($status & 0xFF << 47) >> 47;
			  $core = 		($status & 0xF << 32) >> 32;
			  $errorcode =		($status & 0xFFFF);
			  $ext_errorcode =	($status & 0x1F << 16) >> 16;
			  
			  ($code_type, $bin_tt, $bin_ll, $bin_rrrr, $bin_pp, $bin_t, $bin_ii) = decodeErrorCode($errorcode);
			  
			  # print $bank." : ".sprintf("%x", ($addr >> 32)).sprintf("%x", ($addr & 0xFFFFFFFF))."\n";

			  
			  if($ext_errorcode == 0b00000) 
                          {
                              $error_type = "Reserved" ;
                          }
                          if($ext_errorcode == 0b00001 &&   $code_type eq "bus" &&  $bin_pp == PP_OBS &&   $bin_t == T_0     &&         $bin_rrrr == RRRR_GEN && 
                                          $bin_ii == II_GEN &&  $bin_ll == LL_LG &&     $uc == 1 &&     $addrv == 0 &&          $pcc == 1 && $cecc == 0 && $uecc == 0 && $scrub == 0) 
                          {
                              $error_type = "CRC Error" ;
                              $addr = ($addr & 0xFFFFFFFFFFFE) >> 1;
                              $addr_desc = "Physical";
                              $link = $link;
                              $core = "N/A";  
                              $syndrome = "N/A";                            
                          }
                          if($ext_errorcode == 0b00010 &&   $code_type eq "bus" &&  $bin_pp == PP_OBS &&   $bin_t == T_0     &&         $bin_rrrr == RRRR_GEN && 
                                          $bin_ii == II_GEN &&  $bin_ll == LL_LG &&     $uc == 1 &&     $addrv == 0 &&          $pcc == 1 && $cecc == 0 && $uecc == 0 && $scrub == 0) 
                          {
                              $error_type = "Sync Error" ;
                              $addr = ($addr & 0xFFFFFFFFFFFE) >> 1;
                              $addr_desc = "Physical";
                              $link = $link;
                              $core = "N/A";  
                              $syndrome = "N/A";                            
                          }
                          if($ext_errorcode == 0b00011 &&   $code_type eq "bus" &&  ($bin_pp == PP_SRC || $bin_pp == PP_OBS) &&   $bin_t == T_0     &&         ($bin_rrrr == RRRR_RD || $bin_rrrr == RRRR_WR) && 
                                          ($bin_ii == II_MEM || $bin_ii == II_IO) &&    $bin_ll == LL_LG &&     $uc == 1 &&     $addrv == 1 &&          $pcc == $pcc &&         $cecc == 0 &&   $uecc == 0 &&   $scrub == 0) 
                          {
                              $error_type = "Master Abort" ; ($pcc == 1) ? $error_type = $error_type.", Source is the core" : $error_type = $error_type;
                              $addr = ($addr & 0xFFFFFFFFFFFE) >> 1;
                              $addr_desc = "Physical";
                              $link = $link;
                              $core = $core;  
                              $syndrome = "N/A";                            
                          }
                          if($ext_errorcode == 0b00100 &&   $code_type eq "bus" &&  ($bin_pp == PP_SRC || $bin_pp == PP_OBS) &&   $bin_t == T_0     &&         ($bin_rrrr == RRRR_RD || $bin_rrrr == RRRR_WR) && 
                                          ($bin_ii == II_MEM || $bin_ii == II_IO) &&    $bin_ll == LL_LG &&     $uc == 1 &&     $addrv == 1 &&          $pcc == $pcc &&         $cecc == 0 &&   $uecc == 0 &&   $scrub == 0)
                          {
                              $error_type = "Target Abort" ; ($pcc == 1) ? $error_type = $error_type.", Source is the core" : $error_type = $error_type;
                              $addr = ($addr & 0xFFFFFFFFFFFE) >> 1;
                              $addr_desc = "Physical";
                              $link = $link;
                              $core = $core;  
                              $syndrome = "N/A";                            
                          }
                          if($ext_errorcode == 0b00101 &&   $code_type eq "tlb" &&  $bin_pp == $bin_pp &&   $bin_t == $bin_t     &&         $bin_rrrr == $bin_rrrr && 
                                          $bin_ii == II_GEN &&  $bin_ll == LL_LG &&     $uc == 1 &&     $addrv == 1 &&          $pcc == $pcc &&         $cecc == 0 &&   $uecc == 0 &&   $scrub == 0) 
                          {
                              $error_type = "GART Error" ; ($pcc == 1) ? $error_type = $error_type.", Source is the core" : $error_type = $error_type;
                              $addr = ($addr & 0xFFFFFFFFFFFE) >> 1;
                              $addr_desc = "Physical";
                              $link = "N/A";
                              $core = $core;  
                              $syndrome = "N/A";                            
                          }
                          if($ext_errorcode == 0b00110 &&   $code_type eq "bus" &&  $bin_pp == PP_OBS &&   $bin_t == T_0     &&         $bin_rrrr == RRRR_GEN && 
                                          $bin_ii == II_IO &&   $bin_ll == LL_LG &&     $uc == 1 &&     $addrv == 1 &&          $pcc == 0 &&    $cecc == 0 &&   $uecc == 0 &&   $scrub == 0) 
                          {
                              $error_type = "RMW Error" ;
                              $addr = ($addr & 0xFFFFFFFFFFFE) >> 1;
                              $addr_desc = "Physical";
                              $link = $link;
                              $core = "N/A";  
                              $syndrome = "N/A";                            
                          }
                          if($ext_errorcode == 0b00111 &&   $code_type eq "bus" &&  $bin_pp == PP_GEN &&   $bin_t == T_1     &&         $bin_rrrr == RRRR_GEN && 
                                          $bin_ii == II_GEN &&  $bin_ll == LL_LG &&     $uc == 1 &&     $addrv == 0 &&          $pcc == 1 && $cecc == 0 && $uecc == 0 && $scrub == 0) 
                          {
                              $error_type = "WDT Error" ;
                              $addr = ($addr & 0xFFFFFFFFFFFE) >> 1;
                              $addr_desc = "Physical";
                              $link = "N/A";
                              $core = "N/A";  
                              $syndrome = "N/A";                            
                          }
                          if($ext_errorcode == 0b01000 &&   $code_type eq "bus" &&  ($bin_pp == PP_SRC || $bin_pp == PP_RES) &&   $bin_t == T_0     &&         ($bin_rrrr == RRRR_RD || $bin_rrrr == RRRR_WR) && 
                                          $bin_ii == II_MEM &&  $bin_ll == LL_LG &&     $uc == $uc &&     $addrv == 1 &&          $pcc == $pcc &&     $cecc == $cecc &&   $uecc == $uecc &&   $scrub == $scrub) 
                          {
                              $error_type = "ECC Error" ; ($uc == 1) ? $error_type = $error_type.", Multi Symbol Error" : $error_type = $error_type; ($pcc == 1) ? $error_type = $error_type.", Source is the core" : $error_type = $error_type;
                              $addr = ($addr & 0xFFFFFFFFFFFE) >> 1;
                              $addr_desc = "Physical";
                              $link = "N/A";
                              $core = "N/A";  
                              $syndrome = $syndrome;                            
                          }
                          if($ext_errorcode == 0b01010 &&   $code_type eq "bus" &&  ($bin_pp == PP_SRC || $bin_pp == PP_OBS) &&   $bin_t == T_0     &&         ($bin_rrrr == RRRR_RD || $bin_rrrr == RRRR_WR) && 
                                          ($bin_ii == II_MEM || $bin_ii == II_IO) &&    $bin_ll == LL_LG &&     $uc == 1 &&     $addrv == 1 &&          $pcc == 0 &&    $cecc == 0 &&   $uecc == 0 &&   $scrub == 0) 
                          {
                              $error_type = "Link Data Error" ;
                              $addr = ($addr & 0xFFFFFFFFFFFE) >> 1;
                              $addr_desc = "Physical";
                              $link = $link;
                              $core = "N/A";  
                              $syndrome = "N/A";                            
                          }
                          if($ext_errorcode == 0b01011 &&   $code_type eq "bus" &&  $bin_pp == PP_OBS &&   $bin_t == T_0     &&         $bin_rrrr == RRRR_GEN && 
                                          $bin_ii == II_GEN &&  $bin_ll == LL_LG &&     $uc == 1 &&     $addrv == $addrv &&          $pcc == 1 &&    $cecc == 0 &&   $uecc == 0 &&   $scrub == 0) 
                          {
                              $error_type = "Protocol Error" ;
                              $addr = ($addr & 0xFFFFFFFFFFFE) >> 1;
                              $addr_desc = "Physical";
                              $link = $link;
                              $core = "N/A";  
                              $syndrome = "N/A";                            
                          }
                          if($ext_errorcode == 0b01100 &&   $code_type eq "bus" &&  $bin_pp == PP_OBS &&   $bin_t == T_0     &&         $bin_rrrr == RRRR_GEN && 
                                          $bin_ii == II_GEN &&  $bin_ll == LL_LG &&     $uc == 1 &&     $addrv == 1 &&          $pcc == 1 &&    $cecc == 0 &&   $uecc == 0 &&   $scrub == 0) 
                          {
                              $error_type = "NB Array Error" ;
                              $addr = ($addr & 0xFFFFFFFFFFFE) >> 1;
                              $addr_desc = "Physical";
                              $link = "N/A";
                              $core = "N/A";  
                              $syndrome = "N/A";                            
                          }
                          if($ext_errorcode == 0b01101 &&   $code_type eq "bus" &&  $bin_pp == PP_OBS &&   $bin_t == T_0     &&         $bin_rrrr == RRRR_GEN && 
                                          $bin_ii == II_MEM &&  $bin_ll == LL_LG &&     $uc == 1 &&     $addrv == 0 &&          $pcc == 1 &&    $cecc == 0 &&   $uecc == 0 &&   $scrub == 0) 
                          {
                              $error_type = "DRAM Parity Error" ; $error_type = sprintf("$error_type, caused by DCT %d", $link);
                              $addr = ($addr & 0xFFFFFFFFFFFE) >> 1;
                              $addr_desc = "Physical";
                              $link = "N/A";
                              $core = "N/A";  
                              $syndrome = "N/A";                            
                          }
                          if($ext_errorcode == 0b01110 &&   $code_type eq "bus" &&  $bin_pp == PP_OBS &&   $bin_t == T_0     &&         $bin_rrrr == RRRR_GEN && 
                                          $bin_ii == II_GEN &&  $bin_ll == LL_LG &&     $uc == 0 &&     $addrv == 0 &&          $pcc == 0 &&    $cecc == 0 &&   $uecc == 0 &&   $scrub == 0) 
                          {
                              $error_type = "Link Retry" ;
                              $addr = ($addr & 0xFFFFFFFFFFFE) >> 1;
                              $addr_desc = "Physical";
                              $link = $link;
                              $core = "N/A";  
                              $syndrome = "N/A";                            
                          }
                          if($ext_errorcode == 0b01111 &&   $code_type eq "tlb" &&  $bin_pp == $bin_pp &&   $bin_t == $bin_t     &&         $bin_rrrr == $bin_rrrr && 
                                          $bin_ii == II_GEN &&  $bin_ll == LL_LG &&     $uc == 1 &&     $addrv == 1 &&          $pcc == 0 &&    $cecc == 0 &&   $uecc == 0 &&   $scrub == 0) 
                          {
                              $error_type = "GART Table Walk Data Error" ;
                              $addr = ($addr & 0xFFFFFFFFFFFE) >> 1;
                              $addr_desc = "Physical";
                              $link = "N/A";
                              $core = "N/A";  
                              $syndrome = "N/A";                            
                          }
                          if($ext_errorcode == 0b11100 &&   $code_type eq "mem" &&  $bin_pp == $bin_pp &&   $bin_t == $bin_t     &&         ($bin_rrrr == RRRR_RD || $bin_rrrr == RRRR_EVICT || $bin_rrrr == RRRR_PROBE || $bin_rrrr == RRRR_GEN) && 
                                          $bin_tt== TT_G &&  $bin_ll == LL_LG &&     $uc == $uc &&     $addrv == 1 &&          $pcc == $pcc &&       $cecc == $cecc &&       $uecc == $uecc &&       $scrub == $scrub) 
                          {
                              $error_type = "L3 Cache Data Error"; ($uc == 1) ? $error_type = $error_type.", Multi bit Error" : (($cecc == 1) ? $error_type = $error_type.", Single bit Error" : $error_type = $error_type);
                                                                    $error_type = sprintf("$error_type, Cache Way - %d, Subcache no - %d", $link, $l3_subcache); 
                              $addr = ($addr & 0xFFFFFFFFFFFE) >> 1;
                              $addr_desc = "Physical";
                              $link = $link;
                              $core = ($bin_tt > 0) ? $core : "N/A";  
                              $syndrome = $syndrome;                            
                          }
                          if($ext_errorcode == 0b11101 &&   $code_type eq "mem" &&  $bin_pp == $bin_pp &&   $bin_t == $bin_t     &&         ($bin_rrrr == RRRR_RD || $bin_rrrr == RRRR_EVICT || $bin_rrrr == RRRR_PROBE || $bin_rrrr == RRRR_GEN) && 
                                          $bin_tt== TT_G &&  $bin_ll == LL_LG &&     $uc == $uc &&     $addrv == 1 &&          $pcc == $pcc &&       $cecc == $cecc &&       $uecc == $uecc &&       $scrub == $scrub) 
                          {
                              $error_type = "L3 Cache Tag Error"; ($uc == 1) ? $error_type = $error_type.", Multi bit Error" : (($cecc == 1) ? $error_type = $error_type.", Single bit Error" : $error_type = $error_type); 
                                                                    $error_type = sprintf("$error_type, Cache Way - %d, Subcache no - %d", $link, $l3_subcache); 
                              $addr = ($addr & 0xFFFFFFFFFFFE) >> 1;
                              $addr_desc = "Physical";
                              $link = $link;
                              $core = ($bin_tt > 0) ? $core : "N/A";  
                              $syndrome = $syndrome;                            
                          }
                          if($ext_errorcode == 0b11110 &&   $code_type eq "mem" &&  $bin_pp == $bin_pp &&   $bin_t == $bin_t     &&         ($bin_rrrr == RRRR_RD || $bin_rrrr == RRRR_EVICT || $bin_rrrr == RRRR_PROBE || $bin_rrrr == RRRR_GEN) && 
                                          $bin_tt== TT_G &&  $bin_ll == LL_LG &&     $uc == 0 &&     $addrv == 1 &&          $pcc == 0 &&       $cecc == 0 &&       $uecc == 0 &&       $scrub == 0) 
                          {
                              $error_type = "L3 Cache LRU Error"; 
                              $addr = ($addr & 0xFFFFFFFFFFFE) >> 1;
                              $addr_desc = "Physical";
                              $link = "N/A";
                              $core = "N/A";  
                              $syndrome = "N/a";                            
                          }
                          if($ext_errorcode == 0b11111 &&   $code_type eq "mem" &&  $bin_pp == $bin_pp &&   $bin_t == $bin_t     &&         ($bin_rrrr == RRRR_RD || $bin_rrrr == RRRR_EVICT || $bin_rrrr == RRRR_PROBE || $bin_rrrr == RRRR_GEN) && 
                                          $bin_tt== TT_G &&  $bin_ll == LL_LG &&     $uc == 0 &&     $addrv == 1 &&          $pcc == 0 &&       $cecc == $cecc &&       $uecc == $uecc &&       $scrub == $scrub) 
                          {
                              $error_type = "Probe Filter Error"; ($uecc == 1) ? $error_type = $error_type.", Multi bit Error" : (($cecc == 1) ? $error_type = $error_type.", Single bit Error" : $error_type = $error_type); 
                                                                    $error_type = sprintf("$error_type, Cache Way - %d, Subcache no - %d", $link, $l3_subcache); 
                              $addr = ($addr & 0xFFFFFFFFFFFE) >> 1;
                              $addr_desc = "Physical";
                              $link = $link;
                              $core = ($bin_tt > 0) ? $core : "N/A";  
                              $syndrome = $syndrome;                            
                          }
                          if($ext_errorcode == 0b11001 &&   $code_type eq "mem" &&  $bin_pp == PP_OBS &&   $bin_t == T_0     &&         $bin_rrrr == RRRR_WR && 
                                          $bin_tt== TT_D &&  $bin_ll == LL_LG &&     $uc == 1 &&     $addrv == 0 &&          $pcc == 1 &&       $cecc == 0 &&       $uecc == 0 &&       $scrub == 0) 
                          {
                              $error_type = "Compute Unit Data Error" ;
                              $addr = ($addr & 0xFFFFFFFFFFFE) >> 1;
                              $addr_desc = "Physical";
                              $link = "N/A";
                              $core = $core;  
                              $syndrome = "N/A";                            
                          }


			}
  if($bank == 5)	{# print "bank5 : $status\n"
			  $val = 		($status & 1 << 63) ? 1 : 0;
			  $ov = 		($status & 1 << 62) ? 1 : 0;
			  $uc =			($status & 1 << 61) ? 1 : 0;
			  $en = 		($status & 1 << 60) ? 1 : 0;
			  $miscv =		($status & 1 << 59) ? 1 : 0;
			  $addrv =		($status & 1 << 58) ? 1 : 0;
			  $pcc =		($status & 1 << 57) ? 1 : 0;
			  $cecc = 		"N/A";
			  $uecc = 		"N/A";
			  $def =		"N/A";
			  $poison =		"N/A";
			  $scrub =		"N/A";
			  $link =		"N/A";
			  $cache_way = 	        "N/A";
			  $syndrome = 		"N/A";
			  $core = 		"N/A";
			  $errorcode =		($status & 0xFFFF);
			  $ext_errorcode =	($status & 0x1F << 16) >> 16;
			  
			  ($code_type, $bin_tt, $bin_ll, $bin_rrrr, $bin_pp, $bin_t, $bin_ii) = decodeErrorCode($errorcode);

                          if($ext_errorcode == 0x0 &&   $code_type eq "bus" &&  $bin_pp == PP_GEN &&   $bin_t == T_1     &&         $bin_rrrr == RRRR_GEN && 
                                          $bin_ii== II_GEN &&  $bin_ll == LL_LG &&     $uc == 1 &&     $addrv == 1 &&          $pcc == 1) 
                          {
                              $error_type = "WDT Error" ;                                                        
                          }
                          if($ext_errorcode == 0x1 &&   $code_type eq "bus" &&  $bin_pp == PP_GEN &&   $bin_t == T_0     &&         $bin_rrrr == RRRR_GEN && 
                                          $bin_ii== II_GEN &&  $bin_ll == LL_LG &&     $uc == $uc &&     $addrv == 0 &&          $pcc == 0) 
                          {
                              $error_type = "Internal Error : Wakwup array dest tag parity" ;                                                        
                          }
                          if($ext_errorcode == 0x2 &&   $code_type eq "bus" &&  $bin_pp == PP_GEN &&   $bin_t == T_0     &&         $bin_rrrr == RRRR_GEN && 
                                          $bin_ii== II_GEN &&  $bin_ll == LL_LG &&     $uc == $uc &&     $addrv == 1 &&          $pcc == 0) 
                          {
                              $error_type = "Internal Error : AG Payload Array Parity" ;                                                        
                          }
                          if($ext_errorcode == 0x3 &&   $code_type eq "bus" &&  $bin_pp == PP_GEN &&   $bin_t == T_0     &&         $bin_rrrr == RRRR_GEN && 
                                          $bin_ii== II_GEN &&  $bin_ll == LL_LG &&     $uc == $uc &&     $addrv == 1 &&          $pcc == 0) 
                          {
                              $error_type = "Internal Error : EX Payload Array Parity" ;                                                        
                          }
                          if($ext_errorcode == 0x4 &&   $code_type eq "bus" &&  $bin_pp == PP_GEN &&   $bin_t == T_0     &&         $bin_rrrr == RRRR_GEN && 
                                          $bin_ii== II_GEN &&  $bin_ll == LL_LG &&     $uc == $uc &&     $addrv == 1 &&          $pcc == 0) 
                          {
                              $error_type = "Internal Error : IDRF Array Parity" ;                                                        
                          }
                          if($ext_errorcode == 0x5 &&   $code_type eq "bus" &&  $bin_pp == PP_GEN &&   $bin_t == T_0     &&         $bin_rrrr == RRRR_GEN && 
                                          $bin_ii== II_GEN &&  $bin_ll == LL_LG &&     $uc == 1 &&     $addrv == 1 &&          $pcc == 0) 
                          {
                              $error_type = "Retire dispatch queue parity, Causes Shutdown" ;                                                        
                          }
                          if($ext_errorcode == 0x6 &&   $code_type eq "bus" &&  $bin_pp == PP_GEN &&   $bin_t == T_0     &&         $bin_rrrr == RRRR_GEN && 
                                          $bin_ii== II_GEN &&  $bin_ll == LL_LG &&     $uc == $uc &&     $addrv == 1 &&          $pcc == 0) 
                          {
                              $error_type = ($uc == 1) ? "Mapper Checkpoint Array Parity, Causes shutdown" : "Mapper Checkpoint Array Parity";                                                        
                          }
                          if($ext_errorcode == 0x7 &&   $code_type eq "bus" &&  $bin_pp == PP_GEN &&   $bin_t == T_0     &&         $bin_rrrr == RRRR_GEN && 
                                          $bin_ii== II_GEN &&  $bin_ll == LL_LG &&     $uc == $uc &&     $addrv == 0 &&          $pcc == 0) 
                          {
                              $error_type = "EX0PRF Parity" ;                                                        
                          }
                          if($ext_errorcode == 0x8 &&   $code_type eq "bus" &&  $bin_pp == PP_GEN &&   $bin_t == T_0     &&         $bin_rrrr == RRRR_GEN && 
                                          $bin_ii== II_GEN &&  $bin_ll == LL_LG &&     $uc == $uc &&     $addrv == 0 &&          $pcc == 0) 
                          {
                              $error_type = "EX1PRF Parity" ;                                                        
                          }
                          if($ext_errorcode == 0x9 &&   $code_type eq "bus" &&  $bin_pp == PP_GEN &&   $bin_t == T_0     &&         $bin_rrrr == RRRR_GEN && 
                                          $bin_ii== II_GEN &&  $bin_ll == LL_LG &&     $uc == $uc &&     $addrv == 0 &&          $pcc == 0) 
                          {
                              $error_type = "AG0PRF Parity" ;                                                        
                          }
                          if($ext_errorcode == 0xA &&   $code_type eq "bus" &&  $bin_pp == PP_GEN &&   $bin_t == T_0     &&         $bin_rrrr == RRRR_GEN && 
                                          $bin_ii== II_GEN &&  $bin_ll == LL_LG &&     $uc == $uc &&     $addrv == 0 &&          $pcc == 0) 
                          {
                              $error_type = "AG1PRF Parity" ;                                                        
                          }
                          if($ext_errorcode == 0xB &&   $code_type eq "bus" &&  $bin_pp == PP_GEN &&   $bin_t == T_0     &&         $bin_rrrr == RRRR_GEN && 
                                          $bin_ii== II_GEN &&  $bin_ll == LL_LG &&     $uc == $uc &&     $addrv == 0 &&          $pcc == 0) 
                          {
                              $error_type = "Flag Ragister File parity" ;                                                        
                          }
                          if($ext_errorcode == 0xC &&   $code_type eq "bus" &&  $bin_pp == PP_GEN &&   $bin_t == T_0     &&         $bin_rrrr == RRRR_GEN && 
                                          $bin_ii== II_GEN &&  $bin_ll == LL_LG &&     $uc == $uc &&     $addrv == 0 &&          $pcc == 0) 
                          {
                              $error_type = "DE Error" ;                                                        
                          }

			}			
			
  if($bank == 6)	{# print "bank6 : $status\n"
			  $val = 		($status & 1 << 63) ? 1 : 0;
			  $ov = 		($status & 1 << 62) ? 1 : 0;
			  $uc =			($status & 1 << 61) ? 1 : 0;
			  $en = 		($status & 1 << 60) ? 1 : 0;
			  $miscv =		($status & 1 << 59) ? 1 : 0;
			  $addrv =		($status & 1 << 58) ? 1 : 0;
			  $pcc =		($status & 1 << 57) ? 1 : 0;
			  $cecc = 		"N/A";
			  $uecc = 		"N/A";
			  $def =		"N/A";
			  $poison =		"N/A";
			  $scrub =		"N/A";
			  $link =		"N/A";
			  $cache_way = 	        "N/A";
			  $syndrome = 		"N/A";
			  $core = 		"N/A";
			  $errorcode =		($status & 0xFFFF);
			  $ext_errorcode =	($status & 0x1F << 16) >> 16;
			  
			  ($code_type, $bin_tt, $bin_ll, $bin_rrrr, $bin_pp, $bin_t, $bin_ii) = decodeErrorCode($errorcode);

                          if($ext_errorcode == 0b00101 &&   $code_type eq "bus" &&  $bin_pp == PP_GEN &&   $bin_t == T_0     &&         $bin_rrrr == RRRR_GEN && 
                                          $bin_ii== II_GEN &&  $bin_ll == LL_LG &&     $uc == 1 &&     $addrv == 0 &&          $pcc == 1) 
                          {
                              $error_type = "Floating Point Unit Error : Status Register File" ;                                                        
                          }
                          if($ext_errorcode == 0b00010 &&   $code_type eq "bus" &&  $bin_pp == PP_GEN &&   $bin_t == T_0     &&         $bin_rrrr == RRRR_GEN && 
                                          $bin_ii== II_GEN &&  $bin_ll == LL_LG &&     $uc == 1 &&     $addrv == 0 &&          $pcc == 1) 
                          {
                              $error_type = "Floating Point Unit Error : Physical Register File" ;                                                        
                          }
                          if($ext_errorcode == 0b00001 &&   $code_type eq "bus" &&  $bin_pp == PP_GEN &&   $bin_t == T_0     &&         $bin_rrrr == RRRR_GEN && 
                                          $bin_ii== II_GEN &&  $bin_ll == LL_LG &&     $uc == 1 &&     $addrv == 0 &&          $pcc == 1) 
                          {
                              $error_type = "Floating Point Unit Error : Free List" ;                                                        
                          }
                          if($ext_errorcode == 0b00011 &&   $code_type eq "bus" &&  $bin_pp == PP_GEN &&   $bin_t == T_0     &&         $bin_rrrr == RRRR_GEN && 
                                          $bin_ii== II_GEN &&  $bin_ll == LL_LG &&     $uc == 1 &&     $addrv == 0 &&          $pcc == 1) 
                          {
                              $error_type = "Floating Point Unit Error : Retire Queue" ;                                                        
                          }
                          if($ext_errorcode == 0b00100 &&   $code_type eq "bus" &&  $bin_pp == PP_GEN &&   $bin_t == T_0     &&         $bin_rrrr == RRRR_GEN && 
                                          $bin_ii== II_GEN &&  $bin_ll == LL_LG &&     $uc == 1 &&     $addrv == 0 &&          $pcc == 1) 
                          {
                              $error_type = "Floating Point Unit Error : Scheduler" ;                                                        
                          }
			}			

  $cache_way = ((($cache_way !~ /\D/) && ($cache_way ne ""))) ? sprintf("'%b", $cache_way) : $cache_way;
  $syndrome = ((($syndrome !~ /\D/) && ($syndrome ne ""))) ? sprintf("'%b", $syndrome) : $syndrome;
  $addr = ((($addr !~ /\D/) && ($addr ne ""))) ? sprintf("%x", ($addr >> 32)).sprintf("%x", ($addr & 0xFFFFFFFF)) : $addr;
  $raw_addr = ((($raw_addr !~ /\D/) && ($raw_addr ne ""))) ? sprintf("%x", ($raw_addr >> 32)).sprintf("%x", ($raw_addr & 0xFFFFFFFF)) : $raw_addr;
  # $core = ($core != "N/A") ? sprintf("%b", $core) : $core;    # do not uncomment
  $errorcode = ((($errorcode !~ /\D/) && ($errorcode ne ""))) ? sprintf("'%b", $errorcode) : $errorcode;		
  $ext_errorcode = ((($ext_errorcode !~ /\D/) && ($ext_errorcode ne ""))) ? sprintf("'%b", $ext_errorcode) : $ext_errorcode;	
  
  
  if($error_type eq "N/A") { print "$ext_errorcode\t$code_type\t$bin_tt\t$bin_ll\t$bin_rrrr\t$bin_pp\t$bin_t\t$bin_ii\t$uc\t$addrv\t$pcc\t$cecc\t$uecc\t$def\t$poison\n";}		


  #print "$errorcode\n";
  return "$val\t$ov\t$uc\t$pcc\t$cecc\t$uecc\t$def\t$poison\t$l3_subcache\t$sublink\t$ldtlink\t$scrub\t$link\t$cache_way\t$syndrome\t$core\t$errorcode\t$ext_errorcode\t$error_type\t$raw_addr\t$addr_desc\t$code_type";

}

my $dir = "./";
#my $output_dir = "./";
my $ind= 0, my $bank_no = 0, my $status_code = 0, my $count = 0;
my $line1 = "", my $info = " ";
my $node_id, my $date_time, my $comp_node, my $node_type, my $cpu, my $addr, my $misc = "N/A", my $processor, my $time, my $socket, my $apic;
my $timestamp;
my $numargs = $#ARGV + 1;
if ($numargs != 2){
	print("Usage: ./filename inputfile outputdir\n");
	exit 1;
}

if (-e "$out_file") 
{
  unlink "$out_file";
}

open OUTFILE, ">>$out_file"
  or die "Error opening $out_file : $!";


#open(in_file, "I:/DEPEND/BW Error Analysis/Pearl_Scripts/20130215"); # Keywhan
open(in_file, $input_file);


print OUTFILE "NodeID\tDate Time\tComplete Node\tCabinet\tChassis\tSlot\tNode\tNode Type\tProcessor\tTime\tSocket\tApic\tBank\tErr Val\tOV\tUC\tPCC\tCECC\tUECC\tDEF\tPOISON\tL3 Subcache\tSub Link\tLDT Link\tScrub\tLink\tCache way in error\tSyndrome\tCore\tErrorcode\tExt_errorcode\tError Type\tAddr\tAddr Desc\tErrorcode Type\tMisc\n";

while($a = <in_file>)
{
	chomp($a);
	
	my @values = split(/\t/, $a);
	$info = $values[9]; 		###########*************change to 17 for the original data**************#############
	#print scalar @values."\n";	
	my $arraySize = scalar (@values);
	$arraySize = $#values + 1;  
	  
	if($arraySize == 10)
	{
	  if($info =~ /Machine Check Exception/)
	  {
		  # my $len = scalar @values;
		  #$timestamp = $values[0];
		  $node_id = $values[8];
		  $date_time = $values[1];
		  $comp_node = $values[2];
		  $node_type = $values[3];
		  
		  		  
		  $ind = index($info, "CPU");
		  if($ind != -1)
		  {
			$cpu = substr($info, $ind + 4, 1);
		  }
		  
		  $ind = index($info, "Bank");
		  if($ind != -1)
		  {
			 $bank_no = substr($info, $ind + 5, 1);
			 $status_code = substr($info, $ind + 8, 16);
		  }
		  
		  # print OUTFILE "$values[0]\t$values[1]\t$values[2]\t$values[3]\n";
		  # print "$count\t$len\t$cpu\t$bank_no\t$status_code\n";
		  if(($status_code =~ /^[\da-f]+\z/i) && ($bank_no <= 6 && $bank_no >= 0))
		  {
			$count = 1;
		  }
		  else
		  {
		  	# print "$status_code\n";
		  }
	  }
	  
	  
	  elsif($info =~ /TSC/ && $count == 1)
	  {
		  $ind = index($info, "ADDR");
		  my $ind2 = index($info, "MISC");
		  
		  if($ind != -1)
		  {
		    if($ind2 == -1)
		    {
			$addr = substr($info, $ind + 5, 9);
		    }
		    else
		    {
			$addr = substr($info, $ind + 5, $ind2 - $ind - 6);
		    }
		  }
		  
		  if($ind2 != -1)
		  {
			 $misc = substr($info, $ind2 + 5, 16);
		  }
		  
		  # print OUTFILE "$values[0]\t$values[1]\t$values[2]\t$values[3]\n";
		  # print "$addr\t$misc\n";
		  $count = 2;
	  }
	  
	  
	  elsif($info =~ /PROCESSOR/ && $count == 2)
	  {
		  $ind = index($info, "PROCESSOR");
		  if($ind != -1)
		  {
			$processor = substr($info, $ind + 10, 9);
		  }
		  
		  $ind = index($info, "TIME");
		  if($ind != -1)
		  {
			$time = substr($info, $ind + 5, 10);
		  }		  
		  
		  $ind = index($info, "SOCKET");
		  if($ind != -1)
		  {
			$socket = substr($info, $ind + 7, 1);
		  }
		  
		  $ind = index($info, "APIC");
		  if($ind != -1)
		  {
			$apic = substr($info, $ind + 5, length($info) - $ind + 5);
		  }
		  
		  # print OUTFILE "$values[0]\t$values[1]\t$values[2]\t$values[3]\n";
		  # print "$processor\t$time\t$socket\t$apic\n";
		  $count = 3;
	  }
	  if($count == 3)
	  {
		my $family, my $model;
		my @processor_split = split("", $processor);
		$model = $processor_split[6];
		$family = sprintf("%x", hex("0x".$processor_split[5]) + hex("0x".$processor_split[2]));
		
		my @temp = split("c", $comp_node);
                my $cabinet = $temp[1];
                @temp = split("s", $temp[2]);
                my $chassis = $temp[0];
                @temp = split("n", $temp[1]);
                my $slot = $temp[0];
                my $node = $temp[1];

		if ($family == 15){
			if($bank_no <= 6 && $bank_no >= 0)
			{
				$line1 = decode_15($bank_no, $status_code, $addr);
				print OUTFILE "$node_id\t$date_time\t$comp_node\t$cabinet\t$chassis\t$slot\t$node\t$node_type\t$processor\t$time\t$socket\t$apic\t$bank_no\t$line1\t$misc\n";
			}
		}
		elsif ($family == 10){
			if($bank_no <= 5 && $bank_no >= 0)
			{
				$line1 = decode_10($bank_no, $status_code, $addr);
				print OUTFILE "$node_id\t$date_time\t$comp_node\t$cabinet\t$chassis\t$slot\t$node\t$node_type\t$processor\t$time\t$socket\t$apic\t$bank_no\t$line1\t$misc\n";
			}
		}
		else{
			print("ERROR: $processor(f$family-m$model) unknown\n");
		}
		$count = 0;
	  } 
	} 
}

close(in_file);

close (OUTFILE);
my $personalNow = localtime();
print "... DONE!\n $personalNow -> analysis of Machine Check Exceptions finished\n";
