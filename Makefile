DTS       := glymur-crd.dts
PP        := glymur-crd.dts.pp
DTB       := glymur-crd.dtb
INCLUDES  := -I include

.PHONY: dtb clean check-files update-files

dtb: $(DTB)

$(PP): $(DTS)
	cpp -nostdinc $(INCLUDES) -undef -x assembler-with-cpp $< $@

$(DTB): $(PP)
	dtc -I dts -O dtb -o $@ $< -Wno-unique_unit_address -Wno-simple_bus_reg

clean:
	rm -f $(PP) $(DTB)

check-files:
	./scripts/check-files

update-files:
	./scripts/update-files
