#include <stdio.h>
#include <string.h>

extern char nonboot[512];

typedef unsigned long ulong;
typedef unsigned int uint;
typedef unsigned char ubyte;

void read_sector(char * buf, unsigned long sector);
void write_sector(char * buf, unsigned long sector);

char temp[512];
char input[256];
char * cmd;
char * argv[256];
size_t argc;

struct DiskInfo_T
{
    /* Region start sectors. */
    ulong fat_region;
    ulong root_region;
    ulong data_region;

    /* Other info. */
    ubyte sectors_per_cluster;
    ulong num_sectors;
} disk_info;

/* Get an unsigned integer (in Z80 little-endian)
 * from a buffer at the given position.
 */
uint get_uint(char * buf, uint i)
{
    uint hi = buf[i+1];
    uint lo = buf[i];
    return (hi << 8) | lo;
}

/* Get an unsigned long (in little-endian)
 * from a buffer at a given location.
 */
ulong get_ulong(char* buf, uint i)
{
    ulong hi_hi = buf[i+3];
    ulong hi_lo = buf[i+2];
    ulong lo_hi = buf[i+1];
    ulong lo_lo = buf[i];

    return (hi_hi << 24) | (hi_lo << 16) | (lo_hi << 8) | lo_lo;
}

/* Put an unsigned integer (in Z80 little-endian)
 * into a buffer at a given location.
 */
void set_uint(char * buf, uint i, uint value)
{
    ubyte hi = value >> 8;
    ubyte lo = value & 0x00ff;
    buf[i] = lo;
    buf[i+1] = hi;
}

/* Put an unsigned long (in little-endian)
 * into a buffer at a given location.
 */
void set_ulong(char* buf, uint i, ulong value)
{
    ubyte hi_hi = value >> 24;
    ubyte hi_lo = value >> 16;
    ubyte lo_hi = value >> 8;
    ubyte lo_lo = value & 0x000000ff;

    buf[i] = lo_lo;
    buf[i+1] = lo_hi;
    buf[i+2] = hi_lo;
    buf[i+3] = hi_hi;
}

ulong first_sector_of_cluster(uint n)
{
    return disk_info.data_region + ((n - 2) * disk_info.sectors_per_cluster);
}

int find_file(char * buf, const char * name)
{
    /* Holds filename+extension, maximum 12 characters. */
    char filename[13];
    for (uint i = 0; i < 13; i++)
    {
        filename[i] = 0;
    }

    /* Search just the first sector of the root directory
     * for now. */
    read_sector(temp, disk_info.root_region);

    for (uint f = 0; f < 512; f += 32)
    {
        ubyte attr = temp[f+11];

        /* Skip if not actually a file. */
        if (attr & 0b00011010) continue;

        /* If the first byte of the filename is 0
         * then there are no more files. */
        if (temp[f] == 0) break;

        /* Copy filename. */
        memcpy(filename, &temp[f], 8);

        /* Find first space in filename.
         * If filename is 8 bytes, there won't be one. */
        ubyte i;
        for (i = 0; i < 8; i++)
        {
            if (filename[i] == ' ') break;
        }

        /* i now points to the byte after the last character
         * in the filename. We can start constructing the ext. */
        filename[i] = '.';

        /* Copy extension. */
        memcpy(&filename[i+1], &temp[f+8], 3);

        /* Don't forget the null-terminator! */
        filename[i + 4] = NULL;
        
        /* Compare to search name.
         * If a match, copy directory entry into buffer and return. */
        if (strcmp(filename, name) == 0)
        {
            memcpy(buf, &temp[f], 32);
            return 0;
        }
    }

    return 1;
}

void format_boot_sector()
{
    /* First copy the executable code. We'll overlay everything else onto that. */
    memcpy(temp, nonboot, 512);

    /* Drive signature. */
    temp[510] = 0xAA;
    temp[511] = 0x55;

    /* OS signature */
    memcpy(&temp[3], "makedisk", 8);

    /* Bytes per sector. */
    set_uint(temp, 0x0b, 512);

    /* Sectors per cluster. */
    temp[0x0d] = 2;

    /* 16 reserved sectors. */
    set_uint(temp, 0x0e, 16);

    /* 1 FAT copy. */
    temp[0x10] = 1;

    /* 512 root entries. */
    set_uint(temp, 0x11, 512);

    /* More than 65536 sectors,
        * so set small number of sectors field to 0. */
    set_uint(temp, 0x13, 0);

    /* Media descriptor - 0xf8 for "fixed disk" */
    temp[0x15] = 0xf8;

    /* Sectors per FAT. */
    /* We have 65536 clusters, and each cluster occupies
        * 2 bytes in the FAT. Therefore a FAT takes
        * 65536*2 bytes, or 128Kb (256 sectors) */
    set_uint(temp, 0x16, 256);

    /* Sectors per track */
    /* Disk has no geometry, so set this to 0. */
    set_uint(temp, 0x18, 0);

    /* Number of heads */
    /* Disk has no geometry, so set this to 0. */
    set_uint(temp, 0x1a, 0);

    /* Hidden sectors */
    /* Volume is not partitioned, this is 0. */
    set_ulong(temp, 0x1c, 0);

    /* Large number of sectors */
    set_ulong(temp, 0x20, 131072);

    /* Extended parameters. */
    
    /* Drive number */
    temp[0x24] = 0x18;

    /* Extended boot signature */
    temp[0x26] = 0x29;

    /* Volume serial number */
    set_ulong(temp, 0x27, 1234);

    /* Volume label */
    memcpy(&temp[0x2b], "MAKEDISK   ", 11);

    /* Filesystem type - this must be 'FAT16' */
    memcpy(&temp[0x36], "FAT16   ", 8);

    /* Write bootable sector. */
    write_sector(temp, 0);
}

void format_fat()
{
    /* First two entries are special. */
    temp[0] = 0xf8;
    temp[1] = 0xff;
    temp[2] = 0xff;
    temp[3] = 0xff;

    /* Every other entry is blank. */
    for (uint i = 4; i < 512; i++)
    {
        temp[i] = 0;
    }

    write_sector(temp, disk_info.fat_region);

    for (uint i = 0; i < 512; i++)
    {
        temp[i] = 0;
    }

    /* Now write the rest of the FAT. */
    for (ulong s = disk_info.fat_region + 1; s < disk_info.root_region; s++)
    {
        write_sector(temp, s);
    }
}

/* Initialises filesystem handlers from disk. */
void init_disk()
{
    read_sector(temp, 0);

    /* General disk info. */
    disk_info.sectors_per_cluster = temp[0x0d];

    /* Calculate start of FAT. */
    disk_info.fat_region = get_uint(temp, 0x0e);

    uint sectors_per_fat = get_uint(temp, 0x16);
    uint number_of_fats = temp[0x10];

    /* Calculate start of root directory. */
    disk_info.root_region = disk_info.fat_region + (sectors_per_fat * number_of_fats);

    uint root_directory_size = get_uint(temp, 0x11) / 16;

    /* Calculate start of data region. */
    disk_info.data_region = disk_info.root_region + root_directory_size;

    /* Calculate number of sectors on disk. */
    disk_info.num_sectors = get_uint(temp, 0x13);

    /* If the small number of sectors is 0, read the large number. */
    if (disk_info.num_sectors == 0)
    {
        disk_info.num_sectors = get_ulong(temp, 0x20);
    }
}

int main()
{
    char dir_entry[32];

    puts("Disk Utility for Z80\n\r\n\r");
    
    init_disk();

    /* Interactive prompt. */
    while (1)
    {
        puts("> ");
        gets(input);
        argc = 0;

        /* We expect at least one token. */
        cmd = strtok(input, " ");

        if (cmd == NULL) continue;

        /* Process the rest of the tokens, if any. */
        while (1)
        {
            char * p = strtok(NULL, " ");
            if (p == NULL) break;

            argv[argc] = p;
            argc++;
        }

        if (strcmp(cmd, "type") == 0)
        {
            if (argc < 1)
            {
                puts("Expected at least one argument.\n\r");
            }
            else
            {
                char * filename = argv[0];

                if (find_file(temp, filename) == 0)
                {
                    uint cluster = get_uint(temp, 0x1a);
                    ulong sector = first_sector_of_cluster(cluster);
                    read_sector(temp, sector);
                    puts(temp);
                }
                else
                {
                    printf("Could not find file: %s\n\r", filename);
                }
            }
        }
        else if (strcmp(cmd, "makedisk") == 0)
        {
            /* Format the boot sector. */
            format_boot_sector();

            /* Re-initialise disk based on new boot sector. */
            init_disk();

            /* Format FAT. */
            format_fat();

            /* Now format root directory. */
            
            /* First entry is the volume label.
             * The label here MUST be "MAKEDISK" */
            memcpy(&temp[0], "MAKEDISK   ", 11);

            /* Attribute bytes. */
            temp[11] = 0b00001000;

            /* Second entry is empty. Should be sufficient
             * to set the first byte to 0. */
            temp[32] = 0;

            write_sector(temp, disk_info.root_region);
        }
        else if (strcmp(cmd, "boot") == 0)
        {
            /* Load boot sector and print. */
            read_sector(temp, 0);

            uint index = 0;
            for (uint i = 0; i < 32; i++)
            {
                for (uint j = 0; j < 16; j++)
                {
                    printf("%x ", temp[index]);
                    index++;
                }

                index -= 16;

                puts("| ");

                for (uint j = 0; j < 16; j++)
                {
                    char c = temp[index];

                    if (c < ' ')      c = '.';
                    else if (c > '~') c = '.';

                    printf("%c", c);
                    index++;
                }

                puts("\n\r");
            }

            puts("\n\r");
        }
    }
}
