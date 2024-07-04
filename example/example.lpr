program example;
{$mode objfpc}
{$H+}

uses Classes, SysUtils, ZSTDLib, ZSTD, generics.Hashes, ZStream;

const
  size = 1024*1024*300;

var
  i: Integer;
  t: Double;
  ms, cs, ds: TStream;
  mem: PLongWord;
  hash_before, hash_after: Cardinal;
  compression_level_zstd: Integer;
  compression_level_zlib: Tcompressionlevel;

begin
  compression_level_zstd := 1;
  compression_level_zlib := clfastest;

  t:=Now;
  mem:=GetMem(size);
  for i:=0 to (size-1) div SizeOf(LongWord) do mem[i]:=Random($FF+1); // 1/4 of random
  hash_before:=generics.Hashes.mORMotHasher(0, mem, size);
  WriteLn('Allocating ',size/1024/1024:0:2,' Mb buffer and filling time = ', (Now-t)*SecsPerDay:0:2, ' s');
  WriteLn;


  ms:=TMemoryStream.Create;

  t:=Now;
  cs:=TZSTDCompressStream.Create(ms, compression_level_zstd, 0);
  cs.Write(mem^, size);
  cs.Free;
  WriteLn('Zstd compressed size: ', ms.Position/1024/1024:0:2, ' Mb, time = ', (Now-t)*SecsPerDay:0:2, ' s, compression level = ', compression_level_zstd);

  ms.Seek(0, soBeginning);
  t:=Now;
  ds:=TZSTDDecompressStream.Create(ms);
  ds.Read(mem^, size);
  ds.Free;
  WriteLn('Zstd decompression time = ', (Now-t)*SecsPerDay:0:2, ' s');
  WriteLn;

  hash_after:=generics.Hashes.mORMotHasher(0, mem, size);
  Assert(hash_before=hash_after, 'Zlib hashes not match');


  ms.Seek(0, soBeginning);
  t:=Now;
  cs:=TCompressionStream.Create(clfastest, ms);
  cs.Write(mem^, size);
  cs.Free;
  WriteLn('Zlib compressed size: ', ms.Position/1024/1024:0:2, ' Mb, time = ', (Now-t)*SecsPerDay:0:2, ' s, compression level = ', compression_level_zlib);

  ms.Seek(0, soBeginning);
  t:=Now;
  ds:=TDecompressionStream.Create(ms);
  ds.Read(mem^, size);
  ds.Free;
  WriteLn('Zlib decompression time = ', (Now-t)*SecsPerDay:0:2, ' s');
  WriteLn;

  hash_after:=generics.Hashes.mORMotHasher(0, mem, size);
  Assert(hash_before=hash_after, 'Zlib hashes not match');

  ms.Free;

  WriteLn('Done...');
  ReadLn;
end.

