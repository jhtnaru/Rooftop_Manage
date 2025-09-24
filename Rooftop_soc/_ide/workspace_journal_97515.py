# 2025-09-23T14:53:12.663739
import vitis

client = vitis.create_client()
client.set_workspace(path="Rooftop_soc")

platform = client.create_platform_component(name = "platform_rooftop_0",hw_design = "$COMPONENT_LOCATION/../../soc_rooftop_wrapper_0.xsa",os = "standalone",cpu = "microblaze_riscv_0",domain_name = "standalone_microblaze_riscv_0")

comp = client.create_app_component(name="app_rooftop_0",platform = "$COMPONENT_LOCATION/../platform_rooftop_0/export/platform_rooftop_0/platform_rooftop_0.xpfm",domain = "standalone_microblaze_riscv_0",template = "hello_world")

platform = client.get_component(name="platform_rooftop_0")
status = platform.build()

comp = client.get_component(name="app_rooftop_0")
comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

platform = client.create_platform_component(name = "platform_rooftop_1",hw_design = "$COMPONENT_LOCATION/../../soc_rooftop_wrapper_1.xsa",os = "standalone",cpu = "microblaze_riscv_0",domain_name = "standalone_microblaze_riscv_0")

comp = client.create_app_component(name="app_rooftop_1",platform = "$COMPONENT_LOCATION/../platform_rooftop_1/export/platform_rooftop_1/platform_rooftop_1.xpfm",domain = "standalone_microblaze_riscv_0",template = "hello_world")

platform = client.get_component(name="platform_rooftop_1")
status = platform.build()

comp = client.get_component(name="app_rooftop_1")
comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = comp.clean()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

client.delete_component(name="app_rooftop_1")

client.delete_component(name="platform_rooftop_1")

platform = client.create_platform_component(name = "platform_rooftop_1",hw_design = "$COMPONENT_LOCATION/../../soc_rooftop_wrapper_1.xsa",os = "standalone",cpu = "microblaze_riscv_0",domain_name = "standalone_microblaze_riscv_0")

comp = client.create_app_component(name="app_rooftop_1",platform = "$COMPONENT_LOCATION/../platform_rooftop_1/export/platform_rooftop_1/platform_rooftop_1.xpfm",domain = "standalone_microblaze_riscv_0",template = "hello_world")

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

platform = client.create_platform_component(name = "platform_rooftop_2",hw_design = "$COMPONENT_LOCATION/../../soc_rooftop_wrapper_2.xsa",os = "standalone",cpu = "microblaze_riscv_0",domain_name = "standalone_microblaze_riscv_0")

comp = client.create_app_component(name="app_rooftop_2",platform = "$COMPONENT_LOCATION/../platform_rooftop_2/export/platform_rooftop_2/platform_rooftop_2.xpfm",domain = "standalone_microblaze_riscv_0",template = "hello_world")

platform = client.get_component(name="platform_rooftop_2")
status = platform.build()

comp = client.get_component(name="app_rooftop_2")
comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

vitis.dispose()

