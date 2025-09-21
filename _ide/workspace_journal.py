# 2025-09-21T17:05:52.846017
import vitis

client = vitis.create_client()
client.set_workspace(path="Rooftop_Manage")

client.delete_component(name="app_rooftop")

client.delete_component(name="platform_rooftop")

platform = client.create_platform_component(name = "platform_rooftop",hw_design = "$COMPONENT_LOCATION/../soc_rooftop_wrapper.xsa",os = "standalone",cpu = "microblaze_riscv_0",domain_name = "standalone_microblaze_riscv_0")

comp = client.create_app_component(name="app_rooftop",platform = "$COMPONENT_LOCATION/../platform_rooftop/export/platform_rooftop/platform_rooftop.xpfm",domain = "standalone_microblaze_riscv_0",template = "hello_world")

platform = client.get_component(name="platform_rooftop")
status = platform.build()

comp = client.get_component(name="app_rooftop")
comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

