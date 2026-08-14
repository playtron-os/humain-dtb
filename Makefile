DTS       := glymur-crd.dts
PP        := glymur-crd.dts.pp
DTB       := glymur-crd.dtb
INCLUDES  := -I include

# CamX ships as an overlay, matching Qualcomm's upstream glymur-crd-camx.dtso. Their bootloader
# applies it at runtime via the VendorDtbOverlays efivar; GRUB has no equivalent and discards
# anything firmware applied, so we apply it here with fdtoverlay and ship one merged blob.
#
# The base therefore has to be built with `dtc -@` -- without __symbols__ the overlay has no
# &camss / &soc / &apps_smmu to attach to and fdtoverlay fails.
CAMX_DTSO := glymur-crd-camx.dtso
CAMX_PP   := glymur-crd-camx.dtso.pp
CAMX_DTBO := glymur-crd-camx.dtbo
CAMX_DTB  := glymur-crd-camx.dtb

DTC_FLAGS := -Wno-unique_unit_address -Wno-simple_bus_reg

.PHONY: dtb camx all clean check-files update-files

all: dtb camx

dtb: $(DTB)

# The merged tree that actually ships as glymur-crd-cob.
camx: $(CAMX_DTB)

$(PP): $(DTS)
	cpp -nostdinc $(INCLUDES) -undef -x assembler-with-cpp $< $@

$(DTB): $(PP)
	dtc -@ -I dts -O dtb -o $@ $< $(DTC_FLAGS)

$(CAMX_PP): $(CAMX_DTSO)
	cpp -nostdinc $(INCLUDES) -undef -x assembler-with-cpp $< $@

$(CAMX_DTBO): $(CAMX_PP)
	dtc -@ -I dts -O dtb -o $@ $< $(DTC_FLAGS)

$(CAMX_DTB): $(DTB) $(CAMX_DTBO)
	fdtoverlay -i $(DTB) -o $@ $(CAMX_DTBO)
	@# The overlay is inert if it did not land; assert the result rather than trust it.
	@dtc -I dtb -O dts $@ 2>/dev/null | grep -q 'qcom,camera_x1e80100' || \
		{ echo "FAIL: $@ has no CamX camera node -- overlay did not apply"; exit 1; }
	@echo "$@: CamX overlay applied"

clean:
	rm -f $(PP) $(DTB) $(CAMX_PP) $(CAMX_DTBO) $(CAMX_DTB)

check-files:
	./scripts/check-files

update-files:
	./scripts/update-files
