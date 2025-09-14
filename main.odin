package main

import "core:fmt"
import "core:math"
import "core:os"
import sb "core:strings"
import stbi "vendor:stb/image"

main :: proc() {
	args := os.args
	if len(args) < 2 {
		fmt.eprintln("error: Missing filename")
		fmt.eprintln("usage: <filename> [-d]")
		os.exit(1)
	}
	filename := args[1]

	ascii_chars := "$@#kpJ]!:^'. "
	if len(args) > 2 {
		if args[2] == "-d" {
			ascii_chars = " .'^:!]Jpk#@$"
		}
	}

	img_data, err := os.read_entire_file_or_err(filename)
	if err != nil {
		fmt.eprintln("error:", os.error_string(err))
		os.exit(1)
	}
	defer delete(img_data)

	width, height, channels: i32
	img := stbi.load_from_memory(
		raw_data(img_data),
		i32(len(img_data)),
		&width,
		&height,
		&channels,
		3,
	)
	if img == nil {
		fmt.eprintln("error: Failed to decode image from memory")
		os.exit(1)
	}
	defer stbi.image_free(img)

	new_width: i32 = width < 133 ? width : 133
	new_height := i32(math.round(f64(new_width * height / width) * 0.6))
	scaled_img := make_slice([]u8, new_width * new_height * channels)
	defer delete(scaled_img)

	success := stbi.resize_uint8_srgb(
		img, width, height, 0,
		raw_data(scaled_img), new_width, new_height, 0,
		channels, false, 0
	)

	if success != 1 {
		fmt.eprintln("error: [stb/image]", stbi.failure_reason())
		os.exit(1)
	}

	ascii_line := sb.builder_make_len_cap(0, int(new_width))
	defer sb.builder_destroy(&ascii_line)
	for y in 0 ..< new_height {
		for x in 0 ..< new_width {
			i := (y * new_width + x) * 3

			r := f64(scaled_img[i + 0])
			g := f64(scaled_img[i + 1])
			b := f64(scaled_img[i + 2])

			l := (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255

			sb.write_byte(&ascii_line, ascii_chars[int(math.round(l * 12))])
		}

		fmt.println(sb.to_string(ascii_line))
		sb.builder_reset(&ascii_line)
	}
}
